use audio_visualizer::{Analyzer, PipeWireCapture, VisualizerFrame};
use serde::Deserialize;
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;
use std::process::Command as ProcessCommand;
use std::sync::{Arc, Mutex};
use std::thread;

const SOCKET_PATH: &str = "/tmp/notch-backend.sock";
const VISUALIZER_FRAME_PATH: &str = "/tmp/notch-visualizer.json";

#[derive(Debug, Deserialize)]
#[serde(tag = "command")]
enum BackendCommand {
    #[serde(rename = "volume")]
    Volume { value: f32 },
}

type SharedFrame = Arc<Mutex<Option<VisualizerFrame>>>;

fn get_brightness() -> Result<f32, String> {
    let current = ProcessCommand::new("brightnessctl")
        .arg("get")
        .output()
        .map_err(|error| format!("failed to run brightnessctl: {error}"))?;

    let maximum = ProcessCommand::new("brightnessctl")
        .arg("max")
        .output()
        .map_err(|error| format!("failed to run brightnessctl max: {error}"))?;

    if !current.status.success() || !maximum.status.success() {
        return Err("brightnessctl command failed".to_string());
    }

    let current = String::from_utf8_lossy(&current.stdout)
        .trim()
        .parse::<f32>()
        .map_err(|error| format!("failed to parse current brightness: {error}"))?;

    let maximum = String::from_utf8_lossy(&maximum.stdout)
        .trim()
        .parse::<f32>()
        .map_err(|error| format!("failed to parse maximum brightness: {error}"))?;

    if maximum <= 0.0 {
        return Err("invalid brightness maximum".to_string());
    }

    Ok((current / maximum).clamp(0.0, 1.0))
}

fn set_brightness(value: f32) -> Result<(), String> {
    let percentage = (value.clamp(0.0, 1.0) * 100.0).round();

    let status = ProcessCommand::new("brightnessctl")
        .args(["set", &format!("{percentage}%")])
        .status()
        .map_err(|error| format!("failed to run brightnessctl: {error}"))?;

    if !status.success() {
        return Err(format!("brightnessctl exited with status {status}"));
    }

    Ok(())
}

fn set_volume(value: f32) -> Result<(), String> {
    let percentage = (value.clamp(0.0, 1.0) * 100.0).round();

    let output = ProcessCommand::new("wpctl")
        .args([
            "set-volume",
            "@DEFAULT_AUDIO_SINK@",
            &format!("{percentage}%"),
        ])
        .output()
        .map_err(|error| format!("failed to run wpctl: {error}"))?;

    if !output.status.success() {
        return Err(format!("wpctl exited with status {}", output.status));
    }

    Ok(())
}

fn get_volume() -> Result<f32, String> {
    let output = ProcessCommand::new("wpctl")
        .args(["get-volume", "@DEFAULT_AUDIO_SINK@"])
        .output()
        .map_err(|error| format!("failed to run wpctl: {error}"))?;

    if !output.status.success() {
        return Err(format!("wpctl exited with status {}", output.status));
    }

    let text = String::from_utf8_lossy(&output.stdout);

    let value = text
        .split_whitespace()
        .find_map(|part| part.parse::<f32>().ok())
        .ok_or_else(|| "failed to parse volume".to_string())?;

    Ok(value.clamp(0.0, 1.0))
}

fn handle_connection(stream: UnixStream) {
    let reader = BufReader::new(stream);

    for line in reader.lines() {
        let line = match line {
            Ok(line) => line,
            Err(error) => {
                eprintln!("Socket read error: {error}");
                break;
            }
        };

        if line.trim().is_empty() {
            continue;
        }

        let command = match serde_json::from_str::<BackendCommand>(&line) {
            Ok(command) => command,
            Err(error) => {
                eprintln!("Invalid command: {error}");
                continue;
            }
        };

        match command {
            BackendCommand::Volume { value } => {
                if let Err(error) = set_volume(value) {
                    eprintln!("Volume error: {error}");
                }
            }
        }
    }
}

fn write_frame_file(frame: &VisualizerFrame) {
    let payload = serde_json::json!({
        "bands": frame.bands,
        "rms": frame.rms,
        "peak": frame.peak
    });

    let temporary_path = format!("{VISUALIZER_FRAME_PATH}.tmp");

    if let Err(error) = std::fs::write(&temporary_path, payload.to_string()) {
        eprintln!("Visualizer frame write error: {error}");
        return;
    }

    if let Err(error) = std::fs::rename(&temporary_path, VISUALIZER_FRAME_PATH) {
        eprintln!("Visualizer frame rename error: {error}");
    }
}

fn start_visualizer(frame: SharedFrame) {
    thread::spawn(move || {
        let capture = match PipeWireCapture::new() {
            Ok(capture) => capture,
            Err(error) => {
                eprintln!("Audio visualizer failed to start: {error}");
                return;
            }
        };

        let mut analyzer = Analyzer::new(1024, 24, 48_000.0, 0.45, 0.12, 3.0);

        println!("Audio visualizer started");

        loop {
            let samples = match capture.recv() {
                Ok(samples) => samples,
                Err(error) => {
                    eprintln!("Audio visualizer stopped: {error}");
                    break;
                }
            };

            if let Some(current) = analyzer.process(&samples) {
                write_frame_file(&current);

                if let Ok(mut shared) = frame.lock() {
                    *shared = Some(current);
                }
            }
        }
    });
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    if args.len() == 3 && args[1] == "volume" {
        let value = match args[2].parse::<f32>() {
            Ok(value) => value,
            Err(error) => {
                eprintln!("invalid volume: {error}");
                std::process::exit(1);
            }
        };

        if let Err(error) = set_volume(value) {
            eprintln!("{error}");
            std::process::exit(1);
        }

        return;
    }

    if args.len() == 2 && args[1] == "get-volume" {
        match get_volume() {
            Ok(value) => println!("{value}"),
            Err(error) => {
                eprintln!("{error}");
                std::process::exit(1);
            }
        }

        return;
    }

    if args.len() == 3 && args[1] == "brightness" {
        let value = match args[2].parse::<f32>() {
            Ok(value) => value,
            Err(error) => {
                eprintln!("invalid brightness: {error}");
                std::process::exit(1);
            }
        };

        if let Err(error) = set_brightness(value) {
            eprintln!("{error}");
            std::process::exit(1);
        }

        return;
    }

    if args.len() == 2 && args[1] == "get-brightness" {
        match get_brightness() {
            Ok(value) => println!("{value}"),
            Err(error) => {
                eprintln!("{error}");
                std::process::exit(1);
            }
        }

        return;
    }

    let frame = Arc::new(Mutex::new(None));

    let _ = std::fs::remove_file(SOCKET_PATH);
    let _ = std::fs::remove_file(VISUALIZER_FRAME_PATH);
    let _ = std::fs::remove_file(format!("{VISUALIZER_FRAME_PATH}.tmp"));

    start_visualizer(frame);

    let listener = match std::os::unix::net::UnixListener::bind(SOCKET_PATH) {
        Ok(listener) => listener,
        Err(error) => {
            eprintln!("Failed to create backend socket: {error}");
            return;
        }
    };

    println!("notch-backend listening on {SOCKET_PATH}");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                handle_connection(stream);
            }
            Err(error) => {
                eprintln!("Backend connection error: {error}");
            }
        }
    }

    let _ = std::fs::remove_file(SOCKET_PATH);
}

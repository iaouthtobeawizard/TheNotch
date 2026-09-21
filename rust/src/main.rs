use serde::Deserialize;
use std::io::{BufRead, BufReader};
use std::os::unix::net::{UnixListener, UnixStream};
use std::process::Command as ProcessCommand;

const SOCKET_PATH: &str = "/tmp/notch-backend.sock";

#[derive(Debug, Deserialize)]
#[serde(tag = "command")]
enum BackendCommand {
    #[serde(rename = "volume")]
    Volume { value: f32 },
}
fn get_brightness() -> Result<f32, String> {
    let current = ProcessCommand::new("brightnessctl")
        .arg("get")
        .output()
        .map_err(|error| format!("failed to run brightnessctl: {error}"))?;

    let maximum = ProcessCommand::new("brightnessctl")
        .arg("max")
        .output()
        .map_err(|error| format!("failed to run brightnessctl: {error}"))?;

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

    println!("Setting volume to {percentage}%");

    let output = ProcessCommand::new("wpctl")
        .args([
            "set-volume",
            "@DEFAULT_AUDIO_SINK@",
            &format!("{percentage}%"),
        ])
        .output()
        .map_err(|error| format!("failed to run wpctl: {error}"))?;

    println!("wpctl status: {}", output.status);

    if !output.stdout.is_empty() {
        println!("wpctl stdout: {}", String::from_utf8_lossy(&output.stdout));
    }

    if !output.stderr.is_empty() {
        println!("wpctl stderr: {}", String::from_utf8_lossy(&output.stderr));
    }

    if !output.status.success() {
        return Err(format!("wpctl exited with status {}", output.status));
    }

    Ok(())
}

fn handle_connection(stream: UnixStream) {
    println!("Client connected");

    let reader = BufReader::new(stream);

    for line in reader.lines() {
        let line = match line {
            Ok(line) => line,
            Err(error) => {
                println!("Socket read error: {error}");
                break;
            }
        };

        println!("Received: {line}");

        if line.trim().is_empty() {
            continue;
        }

        let command = match serde_json::from_str::<BackendCommand>(&line) {
            Ok(command) => command,
            Err(error) => {
                println!("Invalid command: {error}");
                continue;
            }
        };

        println!("Parsed command: {command:?}");

        match command {
            BackendCommand::Volume { value } => {
                if let Err(error) = set_volume(value) {
                    println!("Volume error: {error}");
                } else {
                    println!("Volume command completed");
                }
            }
        }
    }

    println!("Client disconnected");
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
    let _ = std::fs::remove_file(SOCKET_PATH);

    let listener = match UnixListener::bind(SOCKET_PATH) {
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
                println!("Incoming connection");
                handle_connection(stream);
            }
            Err(error) => {
                eprintln!("Backend connection error: {error}");
            }
        }
    }

    let _ = std::fs::remove_file(SOCKET_PATH);
}

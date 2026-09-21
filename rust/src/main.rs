use serde::Deserialize;
use std::io::{BufRead, BufReader};
use std::os::unix::net::UnixStream;

const SOCKET_PATH: &str = "/tmp/audio-visualizer.sock";

#[derive(Debug, Deserialize)]
struct VisualizerFrame {
    version: u32,
    sample_rate: u32,
    bands: Vec<f32>,
    rms: f32,
    peak: f32,
}

fn main() {
    let stream = match UnixStream::connect(SOCKET_PATH) {
        Ok(stream) => stream,
        Err(error) => {
            eprintln!("failed to connect to visualizer: {error}");
            return;
        }
    };

    let reader = BufReader::new(stream);

    for line in reader.lines() {
        let line = match line {
            Ok(line) => line,
            Err(error) => {
                eprintln!("visualizer socket error: {error}");
                break;
            }
        };

        if line.trim().is_empty() {
            continue;
        }

        let frame = match serde_json::from_str::<VisualizerFrame>(&line) {
            Ok(frame) => frame,
            Err(_) => continue,
        };

        if frame.version != 1 {
            continue;
        }

        println!(
            "{}",
            serde_json::json!({
                "version": frame.version,
                "sample_rate": frame.sample_rate,
                "bands": frame.bands,
                "rms": frame.rms,
                "peak": frame.peak
            })
        );
    }
}

use opencv::{self as cv, prelude::*, videoio, Result};

fn main() -> Result<()> {
    println!("STARTING");
    let mut cam = videoio::VideoCapture::new(0, videoio::CAP_V4L2)?;
    let opened = videoio::VideoCapture::is_opened(&cam)?;
	if !opened {
		panic!("Unable to open default camera!");
	}
    println!("HAVE_CAM");
    let mut frame = Mat::default();
    println!("HAVE_FRAME");
    cam.read(&mut frame)?;
    println!("READ_FRAME");
    cv::imgcodecs::imwrite("./test.png", &frame, &cv::core::Vector::default())?;
    println!("WROTE_FRAME");
    Ok(())
}

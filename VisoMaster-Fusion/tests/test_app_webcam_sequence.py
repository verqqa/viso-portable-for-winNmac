import cv2
import time
import sys
import numpy as np

# Mocking misc_helpers.read_frame
def read_frame(capture, rotation=0, preview_target_height=None):
    if capture is None or not capture.isOpened():
        return False, None
    ret, frame = capture.read()
    if not ret or frame is None:
        return False, None
    return True, frame

def simulate_app_sequence():
    webcam_index = 0
    webcam_backend = cv2.CAP_ANY
    res_width, res_height = 1280, 720
    
    print("--- Simulating Exact App Webcam Sequence ---")
    
    # 1. Simulate stop_processing() during load_media()
    print("[1] Simulating stop_processing() (which releases current capture if any)...")
    # Let's say there was no previous capture
    media_capture = None
    
    # 2. Simulate load_media() opening webcam
    print("[2] Opening webcam capture inside load_media()...")
    try:
        media_capture = cv2.VideoCapture(webcam_index, webcam_backend)
    except Exception as e:
        print(f"    Error: {e}")
        media_capture = None
        
    if not media_capture or not media_capture.isOpened():
        print("    Failed, retrying with CAP_ANY...")
        if media_capture:
            media_capture.release()
            time.sleep(0.5)
        media_capture = cv2.VideoCapture(webcam_index, cv2.CAP_ANY)
        
    if not media_capture or not media_capture.isOpened():
        print("    [FAIL] Cannot open webcam.")
        return
        
    print("    Webcam opened successfully.")
    
    # Set properties
    media_capture.set(cv2.CAP_PROP_FRAME_WIDTH, res_width)
    media_capture.set(cv2.CAP_PROP_FRAME_HEIGHT, res_height)
    
    # Read first frame (preview frame)
    print("    Reading preview frame inside load_media()...")
    ret, frame = read_frame(media_capture, 0)
    print(f"    Preview frame read: {ret}, shape: {frame.shape if ret else 'N/A'}")
    
    if not ret or frame is None:
        print("    [FAIL] Failed to read preview frame.")
        media_capture.release()
        return
        
    # 3. Simulate refresh_frame(synchronous=True) calling process_current_frame()
    print("[3] Simulating process_current_frame() read...")
    try:
        ret2, frame2 = read_frame(media_capture, 0)
        print(f"    Second frame read (for process): {ret2}, shape: {frame2.shape if ret2 else 'N/A'}")
    except Exception as e:
        print(f"    [CRASH] Error during second read: {e}")
        import traceback
        traceback.print_exc()
        
    media_capture.release()
    print("--- Simulation Ended ---")

if __name__ == "__main__":
    simulate_app_sequence()

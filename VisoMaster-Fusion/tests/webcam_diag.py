import cv2
import time
import sys

def scan_webcams():
    print("=== Webcam Diagnostics Scan ===")
    backends = {
        "Default (CAP_ANY)": cv2.CAP_ANY,
        "DirectShow (CAP_DSHOW)": cv2.CAP_DSHOW,
        "MSMF (CAP_MSMF)": cv2.CAP_MSMF
    }
    
    for index in range(5):
        print(f"\nChecking Webcam Index: {index}")
        any_success = False
        for name, backend in backends.items():
            print(f"  Attempting Backend: {name} ... ", end="")
            sys.stdout.flush()
            try:
                cap = cv2.VideoCapture(index, backend)
            except Exception as e:
                print(f"EXCEPTION: {e}")
                continue
                
            if cap.isOpened():
                w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
                h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
                fps = cap.get(cv2.CAP_PROP_FPS)
                ret, frame = cap.read()
                print(f"SUCCESS! Default: {int(w)}x{int(h)} @ {fps}fps. Frame read: {ret}")
                if ret and frame is not None:
                    print(f"    Frame shape: {frame.shape}")
                    any_success = True
                
                # Check if it supports setting HD
                print("    Trying to set 1280x720 ... ", end="")
                sys.stdout.flush()
                # Close and reopen to avoid MSMF locking issues
                cap.release()
                time.sleep(0.5)
                
                try:
                    cap_hd = cv2.VideoCapture(index, backend)
                    cap_hd.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
                    cap_hd.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
                    ret_hd, frame_hd = cap_hd.read()
                    actual_w = cap_hd.get(cv2.CAP_PROP_FRAME_WIDTH)
                    actual_h = cap_hd.get(cv2.CAP_PROP_FRAME_HEIGHT)
                    print(f"Result: {int(actual_w)}x{int(actual_h)}. Frame read: {ret_hd}")
                    cap_hd.release()
                except Exception as e:
                    print(f"HD EXCEPTION: {e}")
                time.sleep(0.5)
            else:
                print("FAILED")
                if cap:
                    cap.release()

if __name__ == "__main__":
    scan_webcams()

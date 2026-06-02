import sys
import argparse
import traceback
from datetime import datetime
from pathlib import Path


def _write_crash_log(exc: BaseException) -> Path:
    """Persist a full traceback to disk so the diagnostic survives even if the
    console window closes before the user can copy it.

    Returns the path of the written log so the caller can print it.
    """
    log_dir = Path(__file__).resolve().parent / "crash_logs"
    log_dir.mkdir(exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = log_dir / f"crash_{stamp}.log"
    with open(log_path, "w", encoding="utf-8") as f:
        f.write(f"VisoMaster crash report — {datetime.now().isoformat()}\n")
        f.write("=" * 70 + "\n")
        try:
            import platform

            f.write(f"Python:   {sys.version}\n")
            f.write(f"Platform: {platform.platform()}\n")
        except Exception:
            pass
        f.write("=" * 70 + "\n\n")
        traceback.print_exception(type(exc), exc, exc.__traceback__, file=f)
    return log_path


def _run_app() -> None:
    """Boot the Qt app. Imports are inside the function so any startup error is
    captured by the outer try/except (otherwise a top-level import error would
    bypass the crash-log writer)."""
    import argparse
    from PySide6 import QtWidgets, QtCore, QtGui

    class SplashWindow(QtWidgets.QWidget):
        def __init__(self):
            super().__init__()
            self.setWindowFlags(
                QtCore.Qt.FramelessWindowHint
                | QtCore.Qt.SplashScreen
                | QtCore.Qt.WindowStaysOnTopHint
            )
            self.setAttribute(QtCore.Qt.WA_TranslucentBackground)

            # Main layout
            layout = QtWidgets.QVBoxLayout(self)
            layout.setContentsMargins(10, 10, 10, 10)

            # Custom frame with style (dark glassmorphism style)
            self.frame = QtWidgets.QFrame(self)
            self.frame.setObjectName("SplashFrame")
            self.frame.setStyleSheet(
                """
                QFrame#SplashFrame {
                    background-color: rgba(24, 24, 24, 245);
                    border: 1px solid rgba(80, 80, 80, 180);
                    border-radius: 20px;
                }
            """
            )
            frame_layout = QtWidgets.QVBoxLayout(self.frame)
            frame_layout.setContentsMargins(25, 25, 25, 25)
            frame_layout.setAlignment(QtCore.Qt.AlignCenter)

            # Find Aitotts.png
            logo_path = None
            paths_to_check = [
                Path(__file__).resolve().parent.parent / "Aitotts.png",  # parent directory
                Path(__file__).resolve().parent / "Aitotts.png",         # root directory
                Path(__file__).resolve().parent / "app/ui/core/media/visomaster_logo.png",  # fallback
            ]
            for p in paths_to_check:
                if p.is_file():
                    logo_path = p
                    break

            # Logo image
            self.logo_label = QtWidgets.QLabel()
            self.logo_label.setAlignment(QtCore.Qt.AlignCenter)
            if logo_path:
                pixmap = QtGui.QPixmap(str(logo_path))
                if not pixmap.isNull():
                    # Scale logo nicely
                    scaled_pixmap = pixmap.scaled(
                        300, 300, QtCore.Qt.KeepAspectRatio, QtCore.Qt.SmoothTransformation
                    )
                    self.logo_label.setPixmap(scaled_pixmap)
                else:
                    self.logo_label.setText("VisoMaster Fusion")
                    self.logo_label.setStyleSheet(
                        "color: white; font-size: 24px; font-weight: bold; font-family: 'Segoe UI';"
                    )
            else:
                self.logo_label.setText("VisoMaster Fusion")
                self.logo_label.setStyleSheet(
                    "color: white; font-size: 24px; font-weight: bold; font-family: 'Segoe UI';"
                )

            frame_layout.addWidget(self.logo_label)
            frame_layout.addSpacing(20)

            # Loading indicator / Progress bar
            self.progress_bar = QtWidgets.QProgressBar()
            self.progress_bar.setFixedHeight(6)
            self.progress_bar.setRange(0, 100)
            self.progress_bar.setValue(0)
            self.progress_bar.setTextVisible(False)
            self.progress_bar.setStyleSheet(
                """
                QProgressBar {
                    background-color: rgba(255, 255, 255, 20);
                    border: none;
                    border-radius: 3px;
                }
                QProgressBar::chunk {
                    background-color: qlineargradient(x1:0, y1:0, x2:1, y2:0, stop:0 #ff0000, stop:1 #cc0000);
                    border-radius: 3px;
                }
            """
            )
            frame_layout.addWidget(self.progress_bar)
            frame_layout.addSpacing(10)

            # Status text
            self.status_label = QtWidgets.QLabel("Initializing VisoMaster Fusion...")
            self.status_label.setAlignment(QtCore.Qt.AlignCenter)
            self.status_label.setStyleSheet(
                "color: rgba(255, 255, 255, 0.75); font-size: 13px; font-family: 'Segoe UI';"
            )
            frame_layout.addWidget(self.status_label)

            layout.addWidget(self.frame)

            # Window size
            self.resize(380, 440)
            self.center()

        def center(self):
            screen = QtGui.QGuiApplication.primaryScreen()
            if screen:
                geo = screen.availableGeometry()
                x = (geo.width() - self.width()) // 2
                y = (geo.height() - self.height()) // 2
                self.move(x, y)

        def set_progress(self, val: int, status: str):
            self.progress_bar.setValue(val)
            self.status_label.setText(status)
            QtWidgets.QApplication.processEvents()

    parser = argparse.ArgumentParser(description="VisoMaster")
    parser.add_argument(
        "--gpu-id",
        type=int,
        default=0,
        help="CUDA GPU device ID to use (default: 0)",
    )
    args, remaining = parser.parse_known_args()

    app = QtWidgets.QApplication(remaining)

    # Show splash screen immediately
    splash = SplashWindow()
    splash.show()
    splash.set_progress(10, "Initializing theme and styles...")

    import qdarktheme
    from app.ui.core.proxy_style import ProxyStyle

    app.setStyle(ProxyStyle())
    with open("app/ui/styles/true_dark_styles.qss", "r") as f:
        _style = f.read()
        _style = (
            qdarktheme.load_stylesheet(
                theme="dark", custom_colors={"primary": "#4090a3"}
            )
            + "\n"
            + _style
        )
        app.setStyleSheet(_style)

    splash.set_progress(30, "Loading configuration modules...")
    splash.set_progress(50, "Loading UI views and assets...")

    # Import main UI (heavy import)
    from app.ui import main_ui

    splash.set_progress(80, "Initializing MainWindow...")
    window = main_ui.MainWindow(gpu_id=args.gpu_id)

    splash.set_progress(100, "Done!")

    # Show MainWindow first and then close splash screen to prevent premature Qt event loop exit
    QtCore.QTimer.singleShot(600, window.show)
    QtCore.QTimer.singleShot(700, splash.close)

    app.exec()



if __name__ == "__main__":
    try:
        _run_app()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        log_path = _write_crash_log(e)
        print("\n" + "=" * 70)
        print("[FATAL] VisoMaster crashed.")
        print("  Crash log written to:")
        print(f"    {log_path}")
        print(f"  Error: {e}")
        print("=" * 70)
        print("\nFull traceback:")
        traceback.print_exc()
        sys.exit(1)

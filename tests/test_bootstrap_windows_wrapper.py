import os
import unittest


ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WRAPPER_PATH = os.path.join(ROOT_DIR, "scripts", "bootstrap.ps1")
README_PATH = os.path.join(ROOT_DIR, "README.md")


class BootstrapWindowsWrapperTests(unittest.TestCase):
    def test_windows_wrapper_checks_wsl_and_hands_off_to_shell_bootstrap(self) -> None:
        with open(WRAPPER_PATH, "r", encoding="utf-8") as f:
            wrapper = f.read()

        self.assertIn("Get-Command wsl.exe", wrapper)
        self.assertIn("wsl.exe --install -d Ubuntu", wrapper)
        self.assertIn("wsl.exe -l -q", wrapper)
        self.assertIn("wsl.exe bash -lc", wrapper)
        self.assertIn("https://raw.githubusercontent.com/aspain/git-sweaty/main/scripts/bootstrap.sh", wrapper)

    def test_readme_points_windows_quick_start_to_powershell_wrapper(self) -> None:
        with open(README_PATH, "r", encoding="utf-8") as f:
            readme = f.read()

        self.assertIn("scripts/bootstrap.ps1", readme)


if __name__ == "__main__":
    unittest.main()

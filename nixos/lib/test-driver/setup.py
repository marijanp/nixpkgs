from setuptools import setup, find_packages

setup(
  name="nixos-test-driver",
  version='1.0',
  packages=find_packages(exclude=["tests", "tests.*"]),
  entry_points={
    "console_scripts": [
      "nixos-test-driver=test_driver:cli",
      "generate-driver-symbols=test_driver:gen"
    ]
  },
)

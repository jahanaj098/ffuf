#!/bin/bash


install_subfinder() {
    echo "Installing Subfinder..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    if [ $? -eq 0 ]; then
        echo "Subfinder installed successfully."
        echo "Make sure ~/go/bin is in your PATH."
    else
        echo "Failed to install Subfinder."
        exit 1
    fi
}

# Install subfinder
install_subfinder

# Verify installation
echo "Verifying installation..."
if command -v subfinder >/dev/null; then
    echo "Subfinder is installed successfully!"
else
    echo "Something went wrong. Ensure ~/go/bin is in your PATH and try again."
fi

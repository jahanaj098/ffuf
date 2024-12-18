#!/bin/bash


# Function to install subfinder
install_subfinder() {
    echo "Installing Subfinder..."
    go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    if [ $? -eq 0 ]; then
        echo "Subfinder installed successfully."
        echo "Updating PATH for Subfinder..."
        echo 'export PATH=$PATH:~/go/bin' >> ~/.bashrc
        source ~/.bashrc
    else
        echo "Failed to install Subfinder."
        exit 1
    fi
}

# Function to install ffuf
install_ffuf() {
    echo "Installing FFuF..."
    go install github.com/ffuf/ffuf/v2@latest
    if [ $? -eq 0 ]; then
        echo "FFuF installed successfully."
        echo "Make sure ~/go/bin is in your PATH."
    else
        echo "Failed to install FFuF."
        exit 1
    fi
}

# Install tools
install_subfinder
install_ffuf

# Verify installation
echo "Verifying installation..."
if command -v subfinder >/dev/null && command -v ffuf >/dev/null; then
    echo "Both Subfinder and FFuF are installed successfully!"
else
    echo "Something went wrong. Ensure ~/go/bin is in your PATH and try again."
fi

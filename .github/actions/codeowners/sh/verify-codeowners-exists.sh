if [ ! -f .github/CODEOWNERS ]; then
    echo "::error::CODEOWNERS file not found at .github/CODEOWNERS"
    exit 1
fi
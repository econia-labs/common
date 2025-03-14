# Change location to GitHub actions directory.
cd .github/actions

# Iterate over all action directories.
for ACTION_PATH in */; do
    # Change location to action directory.
    cd "$ACTION_PATH"

    ls -al

    # Change location back to GitHub actions directory.
    cd ..
done
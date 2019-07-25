git config user.name "$USER_NAME"
git config user.email "$USER_EMAIL"

git clone $GITHUB_PAGE_REPOSITORY_URL destination
cd source

git checkout master
git pull origin master

find . -maxdepth 1 ! -name '_site' ! -name '.git' ! -name '.gitignore' -exec rm -rf {} \;
mv ../_site/* .

git add -fA
git commit --allow-empty -m "$(git log source -1 --pretty=%B)"
git push -f origin master

echo "Deployed successfully"
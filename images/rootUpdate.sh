#!/bin/bash

#
# Travis builds: Update the submodule version in the root repository
# after a successful build.
#

if [ -z ${SUBMODULE} ]
then
  echo SUBMODULE not set
  exit
fi

echo "Cloning root project..."
git clone https://github.com/gameontext/gameon.git
cd gameon

git checkout modules
REPO=`git config remote.origin.url`
SSH_REPO=${REPO/https:\/\/github.com\//git@github.com:}

# -K $encrypted_f69981374331_key -iv $encrypted_f69981374331_iv
# Get the deploy key by using Travis's stored variables to decrypt deploy_key.enc
if [ -n "$ENCRYPTION_LABEL" ]; then
  ENCRYPTED_KEY_VAR="encrypted_${ENCRYPTION_LABEL}_key"
  ENCRYPTED_IV_VAR="encrypted_${ENCRYPTION_LABEL}_iv"
  ENCRYPTED_KEY=${!ENCRYPTED_KEY_VAR}
  ENCRYPTED_IV=${!ENCRYPTED_IV_VAR}
  openssl aes-256-cbc -K $ENCRYPTED_KEY -iv $ENCRYPTED_IV -in images/go-travis.id_rsa.enc -out images/go-travis.id_rsa -d

  chmod 600 images/go-travis.id_rsa
  eval `ssh-agent -s`
  ssh-add images/go-travis.id_rsa
fi

git config user.email "${GITHUB_EMAIL}"
git config user.name "Travis CI"

# Get the last good submodule
git submodule init ${SUBMODULE}
git submodule update --init --remote --no-fetch ${SUBMODULE}
echo "Checking out submodule ${SUBMODULE} commit ${TRAVIS_COMMIT}"
cd ${SUBMODULE}
git checkout ${TRAVIS_COMMIT}

# Now that we're all set up, we can push the altered submodule to master
cd ..
echo "Pushing my commit..."
git commit -a -m ":arrow_up: Updating to latest version of ${SUBMODULE}..." || true

# If there are no changes to the submodule version (there should be)
if git diff --quiet; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi
echo  git push $SSH_REPO master
#git push $SSH_REPO master || true


#!/bin/bash

# ./setup.sh               Uses ~ as the target directory
# ./setup.sh /some/path    Uses /some/path as the target directory
# you still have to add the prometheus data source and dashboard in grafana manually, i'll work on doing this programatically with grafana as code
TARGET_DIR=${1:-~}

curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$TARGET_DIR/.cargo/env"

sudo apt update
sudo apt install -y libclang-dev pkg-config build-essential gcc tmux
sudo apt install -y git gcc g++ make cmake pkg-config llvm-dev libclang-dev clang

curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> $TARGET_DIR/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew update
brew install prometheus
brew install grafana
brew services start prometheus
brew services start grafana

rm /home/linuxbrew/.linuxbrew/etc/prometheus.yml
curl https://raw.githubusercontent.com/paradigmxyz/reth/main/etc/prometheus/prometheus.yml > /home/linuxbrew/.linuxbrew/etc/prometheus.yml

mkdir $TARGET_DIR/reth
mkdir $TARGET_DIR/reth/data
mkdir $TARGET_DIR/lighthouse
mkdir $TARGET_DIR/lighthouse/data

echo -e "alias lh='lighthouse bn     --checkpoint-sync-url https://mainnet.checkpoint.sigp.io     --execution-endpoint http://localhost:8551     --execution-jwt $TARGET_DIR/jwt.hex   --disable-deposit-contract-sync'" >> $TARGET_DIR/.bashrc
echo -e "alias r='reth node --datadir $TARGET_DIR/reth/data/ --metrics 127.0.0.1:9001 --http --http.addr 0.0.0.0 --http.api All --ws  --authrpc.jwtsecret $TARGET_DIR/jwt.hex'" >> $TARGET_DIR/.bashrc
echo -e "alias both='tmux new-session -d -s lh bash -i -c "lh" \; tmux new-session -d -s r bash -i -c "r"'" >> $TARGET_DIR/.bashrc
echo -e "both" >> $TARGET_DIR/.bashrc
source $TARGET_DIR/.bashrc

openssl rand -hex 32 | tr -d "\n" | sudo tee $TARGET_DIR/jwt.hex

cd ~/lighthouse
git clone https://github.com/sigp/lighthouse.git client
cd client
git checkout stable
make

cd ~/reth
git clone https://github.com/paradigmxyz/reth client
cd client
cargo install --locked --path bin/reth --bin reth

both

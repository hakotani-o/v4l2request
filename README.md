# arch-ubuntu-v4l2request

Orange Pi 5 / Orange Pi 5 Plus（RK3588）向けに **V4L2 Request API** ハードウェアデコードを有効化した **FFmpeg** および **mpv** のパッケージ・ビルドガイドです。

システムの標準ライブラリと競合しないよう、Ubuntu版・Arch Linux版ともに **`/opt/v4l2player`** 配下へインストールされる構成になっています。

---

## 前提条件（共通）

V4L2 Request API 対応の `rkvdec2` ドライバが含まれるカーネル（Linux 7.x 系など）が必要です。また、一般ユーザーでハードウェアデコードを利用するため、`video` および `render` グループへの所属を確認してください。

```bash
sudo usermod -aG video,render "\$USER"
# 設定反映のため、一度ログアウトして再ログインしてください
```

---

## Ubuntu

### 動作確認済み環境
- **OS**: Ubuntu 26.04 LTS (Resolute Raccoon)
- **Kernel**: `7.3.6`

### 1. インストール
```bash
sudo dpkg -i v4l2-request-ffmpeg-mpv*.deb
```

### 2. 環境変数の設定
`~/.bashrc` に以下を追記し、パスを通します。

```bash
export PATH=/opt/v4l2player/bin:\$PATH
export LD_LIBRARY_PATH=/opt/v4l2player/lib:\$LD_LIBRARY_PATH
```
設定後、`source ~/.bashrc` で反映します。

### 3. 再生コマンド例（Wayland）
```bash
WAYLAND_DISPLAY=wayland-0 mpv --vo=gpu-next --gpu-context=wayland --hwdec=v4l2request <動画ファイル名>
```

### 参照ソース・ビルド手順
- **Build Guide**: [ryanfitz/rk3588-v4l2request-mpv-build.md (Gist)](https://gist.github.com/ryanfitz/418c27b7170800d425949d5a3900481b)
- **FFmpeg**: `ryanfitz/FFmpeg` (`rk3588-hevc-rps-controls` ブランチ)
- **mpv**: `ryanfitz/mpv-rockchip` (`rk3588-nv15-gpu-next` ブランチ)

---

## Arch Linux

### 動作確認済み環境
- **OS**: Arch Linux ARM (aarch64)
- **Kernel**: `7.3.6-1`

### 1. インストール
```bash
sudo pacman -U ffmpeg-chewitt-*-aarch64.pkg.tar.xz \
               mpv-v4l2request-*-aarch64.pkg.tar.xz
```

### 2. 環境変数の設定
`~/.bashrc` に以下を追記し、パスを通します。

```bash
export PATH=/opt/v4l2player/bin:\$PATH
export LD_LIBRARY_PATH=/opt/v4l2player/lib:\$LD_LIBRARY_PATH
```
設定後、`source ~/.bashrc` で反映します。

### 3. 再生コマンド例（Wayland）
```bash
WAYLAND_DISPLAY=wayland-0 mpv --vo=dmabuf-wayland --hwdec=v4l2request <動画ファイル名>
```

### 参照ソース・ビルド元
- **FFmpeg**: [chewitt/FFmpeg](https://github.com/chewitt/FFmpeg/) (`rockchip-9.0.1` ブランチ)
- **mpv (PKGBUILD)**: [iuncuim/manjaro-h616](https://github.com/iuncuim/manjaro-h616) (`mpv-v4l2request`)

---

## 謝辞 (Acknowledgments)

素晴らしいソースコードやパッチ、ビルド情報を公開してくださっている開発者の皆様（ryanfitz氏、chewitt氏、iuncuim氏をはじめとするコミュニティの方々）に深く感謝いたします。

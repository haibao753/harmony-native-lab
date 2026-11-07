# Connect a HarmonyOS API 26 cloud build runner

This repository is prepared to build AlgoLab HAPs through GitHub Actions, but the actual Huawei toolchain must be installed on a cloud VM first. A GitHub Actions workflow cannot provision a cloud VM or obtain Huawei's licensed download on the user's behalf.

## Why a dedicated runner

Huawei's Linux CI guidance specifies:
- 64-bit Linux;
- GLIBC 2.28 or later;
- 8 GiB RAM minimum (16 GiB recommended);
- 100 GiB or more disk;
- JDK 21 for Command Line Tools 26.0.0 and later.

The repository is public, but GitHub's standard hosted Ubuntu runner has only 14 GB SSD. It cannot meet Huawei's 100 GB disk requirement. A dedicated self-hosted cloud VM is therefore the reliable path.

Official references:
- [Huawei: Command Line Tools download and integrity verification](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-commandline-get/)
- [Huawei: Linux CI pipeline requirements and HAP build](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-command-line-building-app/)
- [Huawei: DevEco CLI create/build commands](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-deveco-cli-options/)
- [GitHub: self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners)
- [GitHub: standard runner specifications](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)

## 1. Provision a cloud VM

Use a Linux x64 or ARM64 VM with:
- Ubuntu 22.04/24.04 or another supported 64-bit Linux;
- at least 16 GiB RAM recommended;
- at least 100 GiB free disk after the OS is installed;
- GLIBC 2.28+;
- outbound access to GitHub, npm and Huawei's required build/dependency endpoints.

The VM is a paid cloud resource unless your provider offers credits/free quota. Do not create a VM without checking the price and billing period.

## 2. Install the Huawei toolchain

1. Sign in to Huawei Developer and download **Command Line Tools 26.0.0 Release** for the VM's Linux architecture from the official Download Center.
2. Verify the package integrity using Huawei's official Tool Integrity instructions. Do not use third-party mirrors or unverified archives.
3. Extract it so the toolchain root is `/opt/command-line-tools`. The workflow expects the SDK at `/opt/command-line-tools/sdk`.
4. Install JDK 21 at `/opt/jdk-21`.
5. Confirm the SDK includes `/opt/command-line-tools/sdk/default/openharmony`.

The workflow installs the DevEco CLI from npm at run time. If your toolchain is installed elsewhere, set the repository Actions variables below.

## 3. Register the VM as a GitHub self-hosted runner

In `haibao753/harmony-native-lab`:

1. Open **Settings → Actions → Runners → New self-hosted runner**.
2. Select Linux and the VM's architecture.
3. Follow GitHub's on-screen commands on the VM. Add the custom runner label `harmonyos-api-26` while configuring the runner.
4. Install and start the runner service using GitHub's generated instructions.
5. Confirm the runner appears as **Idle** and online in the repository settings.

The runner registration token is short-lived. Enter it only in the VM terminal as GitHub instructs; never paste it into chat, commit it, or store it in repository files.

## 4. Optional repository variables

Defaults are shown below. Add repository Actions variables only if your installation uses different paths:

| Variable | Default |
|---|---|
| `HARMONYOS_COMMANDLINE_TOOL_DIR` | `/opt/command-line-tools` |
| `HARMONYOS_JAVA_HOME` | `/opt/jdk-21` |
| `HARMONYOS_SDK_HOME` | `/opt/command-line-tools/sdk` |

No repository secret is required for the unsigned debug build.

## 5. Run the build

1. Open **Actions → AlgoLab HarmonyOS HAP Build**.
2. Choose **Run workflow** on `feat/algolab-first-native-slice`.
3. Wait for the job to validate VM resources, verify the SDK tools, generate the API 26 Stage project, and run:
   `devecocli build --modules entry --build-mode debug`.
4. Download the `AlgoLab-API26-HAP-...` artifact from the successful workflow run.

The HAP artifact's signing status must be checked before installation. This workflow does not create or store signing certificates or private keys.

## 6. Security

- Keep this runner dedicated to this repository and trusted code. The build workflow is manual-only and does not run arbitrary fork pull requests.
- Do not run untrusted pull-request code on a persistent self-hosted runner.
- Do not commit Huawei toolchain archives, SDK binaries, signing material, private keys, or passwords.
- Stop the cloud VM when it is not needed to avoid unnecessary charges.

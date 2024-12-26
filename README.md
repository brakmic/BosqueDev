# Bosque Development Environment Dockerfile

This repository provides a Dockerfile to build a fully functional Bosque Development Environment. You can either use prebuilt Docker images or build your own image locally.

![Docker Pulls](https://badgen.net/docker/pulls/brakmic/bosquedev?icon=docker)
[![Docker Image Size](https://badgen.net/docker/size/brakmic/bosquedev?icon=docker&label=image%20size)](https://hub.docker.com/r/brakmic/bosquedev/)

## Prebuilt Docker Images
Prebuilt Docker images are available [here](https://hub.docker.com/r/brakmic/bosquedev).  
Pull the image directly using Docker:

```bash
docker pull brakmic/bosquedev:latest
```

## Building Your Own Image
To build the Docker image yourself:

1. Clone this repository.
2. Build the Docker image using the following command:

```bash
docker build -t your_user_prefix/bosquedev:latest .
```

The build process will automatically clone the [BosqueCore](https://github.com/BosqueLanguage/BosqueCore) repository during the build stage, so no additional manual steps are required.

## Running the Docker Container

Run the container interactively with a mounted volume to persist your session.

### For Linux/Mac:
```bash
docker run --rm -it -v $(pwd):/session your_user_prefix/bosquedev:latest
```

### For Windows Users:
- **PowerShell**:
  ```powershell
  docker run --rm -it -v ${PWD}:/session your_user_prefix/bosquedev:latest
  ```

- **Command Prompt (CMD)**:
  ```cmd
  docker run --rm -it -v %cd%:/session your_user_prefix/bosquedev:latest
  ```

- **Git Bash or WSL**:
  ```bash
  docker run --rm -it -v $(pwd):/session your_user_prefix/bosquedev:latest
  ```

## Using the Dockerfile in a Devcontainer

You can use the provided Dockerfile as a development container in VS Code to streamline development.

### What is a DevContainer?
A devcontainer is a [containerized development environment](https://code.visualstudio.com/docs/devcontainers/containers) that allows you to work in a consistent and isolated environment directly from your code editor.

### Setting Up the DevContainer

1. **Install Required Extensions**:
   - Install the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension in VS Code.

2. **Open the Devcontainer Options**:
   - On **macOS**:
     - Open VS Code.
     - Click on the **View** menu > **Command Palette** or press `Cmd+Shift+P`.
   - On **Windows**:
     - Open VS Code.
     - Click on the **View** menu > **Command Palette** or press `Ctrl+Shift+P`.
   - In the Command Palette, search for and select `Dev Containers: Open Folder in Container...`.

3. **Select the Dockerfile**:
   - After selecting the folder containing your project, VS Code will prompt you to configure the devcontainer.
   - If prompted, select `From 'Dockerfile'`.

4. **Configure the DevContainer** (Optional):
   - Ensure there is a `.devcontainer` folder in the root of your project with a `devcontainer.json` file. If it does not exist, create it with the following content:

     ```json
     {
       "name": "Bosque DevContainer",
       "build": {
         "dockerfile": "../Dockerfile"
       },
       "mounts": [
        "context": "..",
        "workspacemount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
        "workspaceFolder": "/project"
       ]
     }
     ```

5. **Build and Open the DevContainer**:
   - VS Code will automatically build the devcontainer and open it.
   - Once the build process is complete, the containerized development environment will be ready.

### Verifying the Environment
- Run `bosque` in the integrated terminal to ensure the command is globally available.
- Verify that the `/workspace` folder contains your project files.

## Features
- **Fully Functional Environment**: Includes all dependencies to develop and run Bosque applications.
- **Global `bosque` Command**: The `bosque` command is globally available, enabling straightforward execution of Bosque scripts.
- **Interactive Development**: Easily test and debug Bosque programs interactively using the container.

## Usage Examples

### Running Bosque Applications
![Running Bosque Application](./assets/images/running_bosque.png)

![Running Another Bosque Application](./assets/images/running_bosque_2.png)

## Additional Resources
- [Bosque-Language (Unofficial)](https://bosque-lang.org)
- [Bosque Language GitHub Organization](https://github.com/BosqueLanguage)

## Contributing
Contributions are welcome! Feel free to submit issues or pull requests to improve this repository.

## License
This project is licensed under the [MIT License](./LICENSE).


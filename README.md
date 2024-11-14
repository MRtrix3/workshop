# WSL image for *MRtrix3* workshop

This container is to be used for the construction of a WSL image for interaction with the *MRtrix3* workshop material.

## Image construction

The following can be executed on any system, and only needs to be performed once.
If performing using PowerShell on a Windows machine,
it may be necessary to first execute the PowerShell as administrator.

1.  Build the Docker image
    ```ShellSession
    docker build . -t mrtrix3_workshop:latest
    ```

2.  Execute a temporary container from that image
    ```ShellSession
    docker run --rm -itd --name temp mrtrix3_workshop:latest
    ```

3.  From another terminal, export the full contents of that running container to a tarball:
    ```ShellSession
    docker export --output=mrtrix3_workshop.tar temp
    ```

4.  Close the running container:
    ```ShellSession
    docker stop temp
    ```

## Image installation

The following is to be executed on all computer laboratory systems using PowerShell.
It should be possible to store file "`mrtrix3_workshop.tar`" from step 3 above on a network file share,
to expedite installation of the image on all destination systems.

1.  Install the image
    ```ShellSession
    wsl --import mrtrix3_workshop install_path mrtrix3_workshop.tar
    ```
    
    "`install_path`" can be changed to any location on the filesystem;
    within the nominated directory a "`ext4.vhdx`" file will be created with the image contents.

2.  Execute the container
    ```ShellSession
    wsl -d mrtrix3_workshop
    ```

3.  Ensure that requisite features of the container are operating as required:
    ```ShellSession
    mrview -info
    ```

    This should ideally show that Direct3D renderer is being used.

+++
title = "Use local images with k3d without any imports"
date = 2024-10-30T15:10:17+05:30
path = "k3d-images"
[taxonomies]
tags = ["k3d"]
+++

Did you know that creation of k3d cluster pulls images around 150 MB everytime? Base images for a cluster at specific version can be reused if they can be shared with the host, however image import comes after the creation of cluster and only solves using images which are pushed to a local docker or k3d managed registry.

I tried a couple of ways to make docker use containerd explicitly and make k3d use that containerd which failed spectacularly. While preparing to try out yet another idea of using local docker as a remote registry (like a proxy) for k3d to pull images from, I stumbled upon a GitHub project which already [implements this mechanism](https://github.com/ligfx/k3d-registry-dockerd) and working as intended.

We will go through the process of using that project here if you need more info than what was presented in that project readme.

I have two fedora systems, one is a server and another is workstation wherein I run docker on the former and podman on the latter and will point out the differences in cluster creation flow.

Version of host machine and k3d binary should make less of a difference and drop a note to let me know otherwise if you face any issues.

## Concept

Container runtime pulls an image from an image registry when a container is scheduled to run on a kubernetes node. For example, `docker.io/hello-world:linux` is pulled from Docker hub and k3d [allows pulling images](https://k3d.io/v5.7.4/usage/registries/#creating-a-registry-proxy-pull-through-registry) from a pull-through cache/registry. However, the simple case is restricted to only pull the image from a single registry.

Now, what happens if we can trap every call to pulling an image and serve the image from somewhere else. The project mentioned above does exactly the same (and some more for user experience), it exposes a registry compatible API for runtime to pull images and internally the call is translated to docker engine API which knows how to pull images from remote registries and finally serves it.

We have an option to either create a registry separately and reuse it everytime k3d cluster is created or create a registry explicitly for each k3d cluster. I use the former as that helps in not only pulling the development images that I build locally to be used directly in the k3d cluster but also reuse the k3d base images which are pulled during cluster creation everytime.

## Usage with Docker

Usage with docker is pretty simple and straightforward, we just swap the docker supplied registry image with `ligfx/k3d-registry-dockerd:v0.5` (latest as of now) and create a k3d cluster using this newly created registry as pull through option.

``` bash
# you can change the port (5000) and name of registry (registry)
k3d registry create -i ligfx/k3d-registry-dockerd:v0.5 -p 5000 \
  -v /var/run/docker.sock:/var/run/docker.sock --proxy-remote-url "*" registry
```

Create a registry config file which mentions to use above created registry for pulling the image and also as a mirror for every image that will be pulled by k3d cluster.

``` bash
# prefix (k3d-) is added for the registry managed by k3d
registry=$(mktemp)
cat << HERE > "$registry"
mirrors:
  "*":
    endpoint:
      - "http://k3d-registry:5000"
HERE
```

All that is left is to create a k3d cluster using above registry configfile and every image will be indirectly pulled by docker on the host and served from there. You can also look at your local docker images and see new images which are used by k3d appear there.

``` bash
k3d cluster create with-docker --registry-use k3d-registry:5000 --registry-config $registry
```

For sharing local images, you can simply build them using local docker and they will automatically be used when container runtime in k3d tries to pulls them and I believe cache invalidation is also handled by this project, nevertheless you can always use a different tag for a clean separation.

## Usage with Podman

If you only use docker, this section can be skipped. However on my workstation I use podman for k3d due to less permission requirements of podman and I don't want to do extra steps for running docker in rootless mode which podman supports out of the box.

Interlude, you can take a look at these videos for understanding a bit more around rootless podman and user permissions. Here are the [links for part1](https://youtu.be/ZgXpWKgQclc) [and part2](https://youtu.be/Ac2boGEz2ww)

You can follow [this guide from k3d docs](https://k3d.io/v5.7.4/usage/advanced/podman/) for a one time setup of podman to work with k3d. Change the steps that are mentioned in the doc at the [last section](https://k3d.io/v5.7.4/usage/advanced/podman/#creating-local-registries) by swapping the registry image as below.

Observe the new argument `--default-network k3d` in below command and this network has to be created (already mentioned in the k3d podman guide) before creating the registry, i.e, `podman network create k3d`. Docker uses a default network with name `bridge` which is prohibited by podman, so we create a new (here the name `k3d` can be different) network.

``` bash
k3d registry create -i ligfx/k3d-registry-dockerd:v0.5 -p 5000 \
  -v /var/run/docker.sock:/var/run/docker.sock --proxy-remote-url "*" \
  --default-network k3d
```

As with docker you can run the same command for creating k3d cluster using the proxy registry, I supplied extra k3s-arg for using rootless mode.

``` bash
# here I'm assuming you already created the registry config file
k3d cluster create with-podman --registry-use k3d-registry:5000 --registry-config $registry \
  --k3s-arg '--kubelet-arg=feature-gates=KubeletInUserNamespace=true@all'
```

## Conclusion

Now we can share the local docker/podman images with k3d cluster without any *explicit* tar of image and importing it into k3d cluster. I suppose with minimal to no tweaks the process can be extended to caching images from private registries as well or an extension to the project might be required. However, above mentioned process fulfills my needs and drop a thank you note to the original author if you wish to.

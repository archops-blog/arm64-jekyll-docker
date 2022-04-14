# Jekyll/GitHub Pages Docker Image for ARM64 

This Jekyll Docker image for M1 Macs that are leveraging GitHub Pages.  

## Build Dockerfile 

```
docker build . -tag jekyllarm64
```

## Run Docker Image 
```
docker run --rm -v "$PWD:/var/jekyll" -p 4000:4000 -it jekyllarm64 jekyll serve --host=0.0.0.0
```

## Docker Hub Image 
[Docker Hub Image](https://hub.docker.com/r/travishankins/arm64-jekyll-docker)

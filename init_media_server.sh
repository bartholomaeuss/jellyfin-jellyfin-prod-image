docker run -d  --name jellyfin\
  --user 1000:0 \
  --net=host \
  --volume ~/jellyfin/config:/config \
  --volume ~/jellyfin/cache:/cache \
  --mount type=bind,source=~/jellyfin/media,target=/media \
  --restart=unless-stopped \
  jellyfin/jellyfin
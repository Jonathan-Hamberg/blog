---
title: FFMPEG RTMP Stream Duplication 
subtitle:
date: 2020-09-30
tags: ["rtmp", "ffmpeg"]
draft: false


---

# Desired Outcome
I recently ran into a situation where I needed to stream a video source to two destinations.  One destination was for YouTube streaming, and the other destination was a local video display server to duplicate the video display across the building.

Typically you would use a service like [Restream](https://restream.io/) to achomplish this goal.  Restream allows you to setup a stream to a single RTMP server which then forwards the stream to a variety of other streaming destinations like YouTube, Facebook, Twitch, etc...

The problem with restream is that it only supported streaming to external destinations and would not work to restream the the local network.

# NGINX
One populare way to achieve this outcome of taking 1 RTMP stream and duplicating the stream to multiple destinations is using NGINX.  NGINX is a fully featured web searver that can also be used as a reverse proxy, load balancer, mail proxy and HTTP cache.  One of it's third party modules adds support for RTMP.  So to get the desired outcome you would host a NGINX web server instance, and then in the configuration file you would indicate the destinations of the duplicated stream.  This is a lot of work for a seemingly simple task of duplicating a RTMP stream.  It may be more reliable, but there is a simpler way using another program.

# FFMPEG
This is where ffmpeg comes into play.  ffmpeg is a complete, cross-fortform solution to record, convert and stream audio and video.  Originally I though ffmpeg was just used for transcoding video and audio from one format to another format.  I recently learned that ffmpeg is very versitile with it's inputs and destinations.  The destination can be a file or in our case a RTMP server.

In this use case we would like ffmpeg to gather video from a RTMP server as an input and then forward that input to 2 RTMP servers.  This is as simple as setting up 2 destinations from mpeg instead of using just one.

Here is the command used to stream to YouTube and also to a RTMP server on the local network.
```sh
ffmpeg -listen 1 -i rtmp://127.0.0.1:1935 \
    -f flv -c copy rtmp://a.rtmp.youtube.com/live2/aaaa-aaaa-aaaa-aaaa-aaaa 
    -f flv -c copy rtmp://192.168.1.50/bbbb-bbbb-bbbb-bbbb-bbbb
```

-listen 1 -i rtmp://127.0.0.1:1935
This indicates that ffmpeg should host a RTMP server for devices to be able to stream to.  This data is then ingested by ffmpeg and then redirected to other streaming destinations.

-f flv -c copy rtmp://a.rtmp.youtube.com/live/aaaa-aaaa-aaaa-aaaa-aaaa
This takes the input video and then copies the input data to the destination rtmp server.  In this case the data is streamed to the YouTube server.  The last aaaa bit of the url is YouTube's stream key so that the user is authenticated to the YouTube channel.
The -c copy field indicates that the data should just be copied and no other operations will be performed.  ffmpeg has the flexibility to perform many operations on the source video/audio before transmitting the data to it's destination. Server operations would be to change the container format or change the video bitrate to something smaller which is more suitable for streaming.

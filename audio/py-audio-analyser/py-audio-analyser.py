import subprocess as sp
import sys
import numpy as np

# tried to use librosa in this version, failed

#import argparse
#import librosa


FFMPEG_BIN = "ffmpeg"

# @see https://aubio.org/manual/latest/cli.html#aubiotrack

# @see https://stackoverflow.com/a/57126101/11301
# python ./py-audio-analyser.py /media/ext1Tb/nextcloud/music/files/04\ electro\ -\ dnb/John\ B/Podcast/JohnBPodcast075.m4a


# see librosa, de ex: https://github.com/librosa/librosa/blob/master/examples/beat_tracker.py
#       https://librosa.github.io/librosa/ioformats.html
#       https://www.programcreek.com/python/example/98223/librosa.load

# for BPM detection see https://stackoverflow.com/a/42934754/11301
# for FFT analysis, see https://www.dummies.com/programming/python/performing-a-fast-fourier-transform-fft-on-a-sound-file/
# for FFT analysis, see https://stackoverflow.com/questions/47982785/python-performing-fft-on-music-file
# for loudness analysis, use this: https://github.com/librosa/librosa/issues/463

print('ASplit.py <src.mp3> <silence duration in seconds> <threshold amplitude 0.0 .. 1.0>')

src = "/media/ext1Tb/nextcloud/music/files/04 electro - dnb/John B/Podcast/JohnBPodcast075.m4a";
#src = "/media/ext1Tb/nextcloud/music/files/02 chilling in/#clasica/Frederic Chopin - Complete Edition 17 CD/Vol I - Piano Concertos/CD1/CDImage.m4a";
#src = "/media/ext1Tb/nextcloud/music/files/02 chilling in/DJ River/DJ_River_-_Ambient_Chillout_Mix_5_-_Autumn_2005_www.djriver.com.m4a";
#src = "/media/ext1Tb/nextcloud/music/files/Radio Guerilla - Zona Libera/Zona Libera - Zona Libera 697___ aired 03 noiembrie 2019 ___.m4a"
#src = "/media/ext1Tb/nextcloud/music/files/04 electro/90 Global Underground/2004.xx.xx Sasha - Involver.m4a"

dur = float(0.5)
silence_duration = float(1.5)
thr = int(1 *65535)
#src = sys.argv[1]
#dur = float(sys.argv[2])
#thr = int(float(sys.argv[3]) * 65535)

#f = open('%s-out.bat' % src, 'wb')

tmprate = 22050
len2 = dur * tmprate
buflen = int(len2     * 2)
#            t * rate * 16 bits

oarr = np.arange(1, dtype='int16')
# just a dummy array for the first chunk

command = [ FFMPEG_BIN,
        '-loglevel', 'panic',
        '-i', src,
        '-f', 's16le',
        '-acodec', 'pcm_s16le',
        '-ar', str(tmprate), # ouput sampling rate
        '-ac', '1', # '1' for mono
        '-']        # - output to stdout

pipe = sp.Popen(command, stdout=sp.PIPE, bufsize=10**8)

tf = True
pos = 0
opos = 0
part = 0


analysisData_timestamp = []
analysisData_min = []
analysisData_max = []
analysisData_median = []
analysisData_average = []

while tf :
    raw = pipe.stdout.read(buflen)
    if raw == '' :
        tf = False
        break;

    arr = np.frombuffer(raw, dtype = "int16")
    rng = np.concatenate([oarr, arr])
    if len(rng)==0:
        tf = False
        break
        
    a = np.absolute(rng)
    
    analysisData_timestamp.append(pos)
    analysisData_min.append(np.min(a))
    analysisData_max.append(np.max(a))
    analysisData_median.append(np.median(a))
    analysisData_average.append(np.average(a))
        
    pos += dur

    oarr = arr
    
if len(rng)!=0:
    a = np.absolute(rng);
    
    analysisData_timestamp.append(pos)
    analysisData_min.append(np.min(a))
    analysisData_max.append(np.max(a))
    analysisData_median.append(np.median(a))
    analysisData_average.append(np.average(a))

#print(analysisData_median)
#print(np.min(analysisData_min))

duration = analysisData_timestamp[-1]
track_max = np.max(analysisData_max)

print("duration: %.1fs" % (duration))                 # TODO: tag as long/short/medium
print("track min: %.1f" % (np.min(analysisData_min)))                
print("track max: %.1f" % (track_max))
if track_max<(float(np.iinfo(np.int16).max)*0.95):
    print("    you should normalise this track. Currently at %.1f%%" % (100*track_max/float(np.iinfo(np.int16).max)))
else:
    print("    already normalised. Currently at %.1f%%" % (100*track_max/float(np.iinfo(np.int16).max)))
print("track median: %.1f" % (np.median(analysisData_median)))       # global median/average can be used to determine local peaks, and then determine if we have multiple tracks in our song
print("track average: %.1f" % (np.average(analysisData_average)))

m = np.median(analysisData_median)
r = [analysisData_timestamp[i] for i in [i for i, v in enumerate(analysisData_median) if v < (m*0.10)]]
silence_intervals = []
t1 = None
tl = 0.0
for t in r:
    if t1 is None:
        t1 = t
    if t-tl > silence_duration:
        silence_intervals.append([tl-t1, t1, tl, ])
        t1 = t
    tl = t
    #print(t)
print("    silence less than median: %s" % (r))
silence_intervals_median = np.median([v[0] for v in silence_intervals if v[0]>=silence_duration] )
print("    silence_intervals median: %.1fs" % (silence_intervals_median))

detected_silence_intervals = [v[0] for v in silence_intervals if v[0]>=silence_intervals_median and v[1]>(duration*0.01) and v[1]<(duration*0.99)]
print("    silence_intervals: %s" % ( detected_silence_intervals )) # if we tagged long and we have less than 5 elements in this list, then we have one-track, and no splitting is needed

# TODO: if you're going to propose slincing by silenge, then the silence should be at a zero-crossing point, in the middle of the separating gap

beat_track(src)

#part += 1    
#print('ffmpeg -i "%s" -ss %f -to %f -c copy -y "%s-p%04d.mp3"\r\n' % (src, opos, pos, src, part))
#f.write('ffmpeg -i "%s" -ss %f -to %f -c copy -y "%s-p%04d.mp3"\r\n' % (src, opos, pos, src, part))
#f.close()

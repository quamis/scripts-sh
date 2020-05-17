import subprocess as sp
import sys
import numpy

FFMPEG_BIN = "ffmpeg"

# @see https://stackoverflow.com/a/57126101/11301
# python ./py-audio-analyser.py /media/ext1Tb/nextcloud/music/files/04\ electro\ -\ dnb/John\ B/Podcast/JohnBPodcast075.m4a


# see librosa, de ex: https://github.com/librosa/librosa/blob/master/examples/beat_tracker.py
#       https://librosa.github.io/librosa/ioformats.html
#       https://www.programcreek.com/python/example/98223/librosa.load

# for BPM detection see https://stackoverflow.com/a/42934754/11301
# for FFT analysis, see https://www.dummies.com/programming/python/performing-a-fast-fourier-transform-fft-on-a-sound-file/
# for FFT analysis, see https://stackoverflow.com/questions/47982785/python-performing-fft-on-music-file
# for loudness analysis, use this: https://github.com/librosa/librosa/issues/463

#print('ASplit.py <src.mp3> <silence duration in seconds> <threshold amplitude 0.0 .. 1.0>')

src = "/var/www/nextcloud/data/lucian.sirbu/files/@muzica.mp3/testing/DM/Depeche Mode - Behind the Wheel (Spice Remix) - contains silence.m4a";
#src = "/media/ext1Tb/nextcloud/music/files/04 electro - dnb/John B/Podcast/JohnBPodcast075.m4a";
#src = "/media/ext1Tb/nextcloud/music/files/02 chilling in/#clasica/Frederic Chopin - Complete Edition 17 CD/Vol I - Piano Concertos/CD1/CDImage.m4a";
#src = "/media/ext1Tb/nextcloud/music/files/02 chilling in/DJ River/DJ_River_-_Ambient_Chillout_Mix_5_-_Autumn_2005_www.djriver.com.m4a";
#src = "/media/ext1Tb/nextcloud/music/files/Radio Guerilla - Zona Libera/Zona Libera - Zona Libera 697___ aired 03 noiembrie 2019 ___.m4a"
#src = "/media/ext1Tb/nextcloud/music/files/04 electro/90 Global Underground/2004.xx.xx Sasha - Involver.m4a"

dur = float(5)
silence_duration = float(1.5)
thr = int(1 *65535)
#src = sys.argv[1]
#dur = float(sys.argv[2])
#thr = int(float(sys.argv[3]) * 65535)

#f = open('%s-out.bat' % src, 'wb')

tmprate = 44100
len2 = dur * tmprate
buflen = int(len2     * 2)
#            t * rate * 16 bits

oarr = numpy.arange(1, dtype='int16')
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

    arr = numpy.frombuffer(raw, dtype = "int16")
    rng = numpy.concatenate([oarr, arr])
    if len(rng)==0:
        tf = False
        break
        
    a = numpy.absolute(rng)
    
    analysisData_timestamp.append(pos)
    analysisData_min.append(numpy.min(a))
    analysisData_max.append(numpy.max(a))
    analysisData_median.append(numpy.median(a))
    analysisData_average.append(numpy.average(a))
    pos += dur
    oarr = arr

   
if len(rng)!=0:
    a = numpy.absolute(rng);
    analysisData_timestamp.append(pos)
    analysisData_min.append(numpy.min(a))
    analysisData_max.append(numpy.max(a))
    analysisData_median.append(numpy.median(a))
    analysisData_average.append(numpy.average(a))

#print(analysisData_median)
#print(numpy.min(analysisData_min))

duration = analysisData_timestamp[-1]
track_max = numpy.max(analysisData_max)

print("duration: %.1fs" % (duration))                 # TODO: tag as long/short/medium

# check if track is normalised
print("track_min: %.1f" % (numpy.min(analysisData_min)))                
print("track_max: %.1f" % (track_max))
if track_max<(float(numpy.iinfo(numpy.int16).max)*0.95):
    # @see https://superuser.com/questions/323119/how-can-i-normalize-audio-using-ffmpeg
    print("    you should normalise this track. Currently at %.1f%%" % (100*track_max/float(numpy.iinfo(numpy.int16).max)))
else:
    print("    already normalised. Currently at %.1f%%" % (100*track_max/float(numpy.iinfo(numpy.int16).max)))
print("track median: %.1f" % (numpy.median(analysisData_median)))       # global median/average can be used to determine local peaks, and then determine if we have multiple tracks in our song
print("track average: %.1f" % (numpy.average(analysisData_average)))

# TODO: check if we have an over-amplified track (lots of +/- max values)


# check if we have a large track split into multiple tracks, with silence in-between
m = numpy.median(analysisData_median)
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
if t-t1 > silence_duration:
    silence_intervals.append([tl-t1, t1, tl, ])
    
print("    silence less than median: %s" % (r))
silence_intervals_median_list = [v[0] for v in silence_intervals if v[0]>=silence_duration]
if len(silence_intervals_median_list):
    silence_intervals_median = numpy.median(silence_intervals_median_list)
    print("    silence_intervals_median: %.1fs" % (silence_intervals_median))

    detected_silence_intervals = [v[0] for v in silence_intervals if v[0]>=silence_intervals_median and v[1]>(duration*0.01) and v[1]<(duration*0.99)]
    print("    silence_intervals: %s" % ( detected_silence_intervals )) # if we tagged long and we have less than 5 elements in this list, then we have one-track, and no splitting is needed

# TODO: if you're going to propose slincing by silenge, then the silence should be at a zero-crossing point, in the middle of the separating gap



# TODO: check if we have a track with silence at the beginning, or at the end. It should be possible to reuse the code from above




#part += 1    
#print('ffmpeg -i "%s" -ss %f -to %f -c copy -y "%s-p%04d.mp3"\r\n' % (src, opos, pos, src, part))
#f.write('ffmpeg -i "%s" -ss %f -to %f -c copy -y "%s-p%04d.mp3"\r\n' % (src, opos, pos, src, part))
#f.close()

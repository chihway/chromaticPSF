#! /bin/sh

# 2012-12-5 Chihway Chang

# Purpose: 
#
# - Extract parameters from OpSim and form a parameter file equivalent 
#   to the trim_* catalogs. 
# - This is the input to the script that actually generates the par files. 
# - This script is for the chromatic PSF test

# these are the parameters fixed for all runs
ra=1.58285320483
dec=0.187414494787
rotsky=0            # important: do everyhing except rotating the 
                    # telescope for that makes it very hard to 
                    # calculate the shear-in vs. shear-out

# filters and chips
Exparray=('273286' '347577' '730544' '714956' '850436' '882594') # all visits
exparray=('56' '80' '184' '184' '160' '160') # visit per galaxy
filterarray=('U' 'G' 'R' 'I' 'Z' 'Y')
chiparray=('00' '01' '11' '22')

# loop over 6 filters
for ((Nfilter=0; Nfilter<=5; Nfilter++))
do
Nexp=${exparray[${Nfilter}]}

# loop over N realizations of the atm and optics
for ((id=1; id<=${Nexp}; id++))
do

# loop over 3 randomly selected chips
for ((chipid=1; chipid<=3; chipid++))
do

# filter, exposures
filter=${filterarray[${Nfilter}]}
NExp=${Exparray[${Nfilter}]}

# select observing conditions from opsim ##########################
Nline=`echo ${id} ${chipid} ${NExp}| awk '{srand($1*100)+$2}{print int(rand()*$3)+2}'`
cat /nfs/slac/g/ki/ki06/lsst/chihway/output_opsim3_61_${filter}.dat|head -${Nline}|tail -1> pars_${id}_${chipid}_${Nfilter}

ID=`echo ${id} ${chipid}_${Nfilter}|awk '{print $1*100+$2}'`
alt=`cat pars_${id}_${chipid}_${Nfilter}|awk '{print $32/3.1415926*180}'`
az=`cat pars_${id}_${chipid}_${Nfilter}|awk '{print $33/3.1415926*180}'`
month=`echo ${id} ${chipid}_${Nfilter}|awk '{print ($1*100+$2)%12+1}'`
mjd=`cat pars_${id}_${chipid}_${Nfilter}|awk '{print $10}'`
spid=`cat pars_${id}_${chipid}_${Nfilter}|awk '{print $15/3.1415926*180}'`
raw_seeing=`cat pars_${id}_${chipid}_${Nfilter}|awk '{print $22}'`
mra=`cat pars_${id}_${chipid}_${Nfilter}|awk '{print $35/3.1415926*180}'`
mdec=`cat pars_${id}_${chipid}_${Nfilter}|awk '{print $36/3.1415926*180}'`
dist2moon=180.0
moonphase=0.0
malt=-90
sunalt=`cat pars_${id}_${chipid}_${Nfilter}|awk '{print $39/3.1415926*180}'`

mv pars_${id}_${chipid}_${Nfilter} /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/pars_chromaticPSF/opsim_pars/filter_${Nfilter}/.

# Write out trim file, this is what the phosim script will take in
# note that objects are included with includeobj command instead of 
# putting entire catalog in there. Plan to generate all the par file 
# and screens on the fly, the only problem may be IO and memory.
#
# The pointing and telescope rotation does not change, so we only 
# need to trim once, I think.

echo "
Unrefracted_RA ${ra}
Unrefracted_Dec ${dec}
Unrefracted_Altitude ${alt}
Unrefracted_Azimuth ${az} 
Slalib_date 1994/${month}/19/0.298822999997 
Opsim_rotskypos 0 
Opsim_rottelpos ${spid} 
Opsim_moonra ${mra}
Opsim_moondec ${mdec}
Opsim_rawseeing ${raw_seeing}
Opsim_expmjd ${mjd}
Opsim_moonalt ${malt}
Opsim_sunalt ${sunalt}
Opsim_filter ${Nfilter} 
Opsim_dist2moon ${dist2moon} 
Opsim_moonphase ${moonphase}
SIM_SEED ${ID} 
SIM_MINSOURCE 1
SIM_TELCONFIG 0 
SIM_CAMCONFIG 1
SIM_NSNAP 1
SIM_VISTIME 15.0 
SIM_TEMPERATURE 283.15
SIM_TEMPVAR 0.0
SIM_ALTVAR 0.0
SIM_CONTROL 0
SIM_ACTUATOR 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0
isDithered 0
ditherRaOffset 0.0
ditherDecOffset 0.0

">trim_${id}_${chipid}_${Nfilter}

mv trim_${id}_${chipid}_${Nfilter} /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/pars_chromaticPSF/trim_pars/filter_${Nfilter}/.

done
done
done

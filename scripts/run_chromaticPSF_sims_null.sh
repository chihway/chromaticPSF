#! /bin/sh

# 2013-1-21 CC
# 
# Puspose: 
# Wrapper script to do simulation for chromatic PSF project. 
# This script makes 7 types of stars, 8 types of galaxies, 
# each on a (~45x45) grid and in 6 filters. "Null" refers to 
# the fact that we're using the telescopemode=0 switch, then 
# gradually build up the other components
#
# The plan: null -> +atm turbulence -> +atm dispersion 
# -> +perfect optics -> +optics perturbations and tracking 
#
# We want to measure a few quantities:
# for all objects:
#   (weighted) second moments
#   centroid
#   ellipticities
#   size
# => the difference between these for different SEDs are calculated
# pairs of star/gal:
#   correct galaxies from stars, residual shear is calculated
#

z=1.0

# choose 3 chips to do this analysis
chiparray=('00' '03' '11' '22')

# 15 types of star SED
sedarray=('' 'CWW_E_ext' 'CWW_Im_ext' 'CWW_Sbc_ext' 'CWW_Scd_ext' 'KIN_SB1_ext' 'KIN_SB6_ext' 'KIN_Sa_ext' 'KIN_Sb_ext' 'uka5v' 'ukb5iii' 'ukf5v' 'ukg5v' 'ukk5v' 'ukm5v' 'uko5v')
                    
# loop over 20 star types
for ((sedid=1; sedid<=8; sedid++)) #15
do

# loop over 100 realizations of the atm and optics
for ((id=1; id<=1; id++)) 
do

# loop over 10 randomly selected chips
for ((chipid=3; chipid<=3; chipid++)) #3
do

# SED type
sedtype=${sedarray[${sedid}]}

echo ${sedtype}

# this is the id as well as the seed
ID=`echo ${sedid} ${id} ${chipid}| awk '{print ($1*10000+$2*10+$3)*100}'`
month=`echo ${ID}|awk '{print $1%12+1}'`

# chip name
chip=R${chiparray[${chipid}]}_S11

for ((filter=0; filter<=5; filter++))
do

echo "
obshistid ${ID}
filter ${filter}
chipid ${chip}
obsseed ${ID}
monthnum ${month}
">pars_chromaticPSF/trim_pars/temp_trim_pars/temp_${sedid}_${id}_${chipid}_${filter}

# need to generate the screens and all that in this directory, not sure why
echo "#! /bin/sh

rm -rf /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir
mkdir -p /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir
cd /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir

cp /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/pars_chromaticPSF/psf_cat/${sedtype}_${filter}_${z}_${chip}.pars ./.
cp /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/work/airglowscreen_dummy.fits ./airglowscreen_${ID}.fits
# dummy screen has zeros all across

# swap in filter and the correct star type)
# make the raytrace file directly... don't go through the phosim script!
# note that all objects are Gaussians here to avoid pixel effects

cat /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/pars_chromaticPSF/trim_pars/dummy >trim_${sedid}_${id}_${chipid}_${filter}
cat /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/pars_chromaticPSF/trim_pars/temp_trim_pars/temp_${sedid}_${id}_${chipid}_${filter} >> trim_${sedid}_${id}_${chipid}_${filter}
cat ${sedtype}_${filter}_${z}_${chip}.pars >> trim_${sedid}_${id}_${chipid}_${filter}

# generate image (image will be generated in the same directory)
/nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/bin/raytrace <  trim_${sedid}_${id}_${chipid}_${filter}

cp eimage_${ID}_${chip}_E000.fits /nfs/slac/g/ki/ki08/chihway/chromaticPSF/simulations/null/filter_${filter}/z_${z}/.

# add background (not sure why this doesn't work for the raytrace)
cp /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/scripts/add_background_old_chromaticPSF_star.sh ./.
add_background_old_chromaticPSF_star.sh ${sedid} ${id} ${chipid} ${filter} /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir 

# measure shape
mkdir master
cp /nfs/slac/g/ki/ki08/chihway/Neff/analysis/shear_errors/measure_shape_se.sh ./.
cp /nfs/slac/g/ki/ki08/chihway/Neff/analysis/shear_errors/*pl ./.
cp /nfs/slac/g/ki/ki08/chihway/Neff/analysis/shear_errors/default* ./.
cp /nfs/slac/g/ki/ki08/chihway/Neff/analysis/shear_errors/star* ./.

./measure_shape_se.sh eimage_${ID}_${chip}_E000 /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir/master star.sex star.param  /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir

mv  /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir/master/* /nfs/slac/g/ki/ki08/chihway/chromaticPSF/simulations/null/filter_${filter}/z_${z}/.

cd /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/
rm -rf  /scratch/chihway/chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}_tempdir
rm /nfs/slac/g/ki/ki06/lsst/chihway/phosim-v-3.2/pars_chromaticPSF/trim_pars/temp_trim_pars/temp_${sedid}_${id}_${chipid}_${filter}

"> submit_scripts/run_chromaticPSF_sims_${sedid}_${id}_${chipid}_${filter}_${z}.sh

chmod +x submit_scripts/run_chromaticPSF_sims_${sedid}_${id}_${chipid}_${filter}_${z}.sh
rm log/log_chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z}
bsub -q kipac-ibq -o log/log_chromaticPSF_${sedid}_${id}_${chipid}_${filter}_${z} submit_scripts/run_chromaticPSF_sims_${sedid}_${id}_${chipid}_${filter}_${z}.sh
#submit_scripts/run_chromaticPSF_sims_${sedid}_${id}_${chipid}_${filter}.sh

sleep 1
done
done
done
done

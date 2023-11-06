#!/bin/csh


# define path to model ingredients
set rsp_models="$LVM_DAP_PATH/_fitting-data/_basis_mastar_v2/stellar-basis-spectra-100.fits.gz"
set rsp_nl_models="$LVM_DAP_PATH/_fitting-data/_basis_mastar_v2/stellar-basis-spectra-5.fits.gz"
# define original CUBE paths
# @mortadelo
set IC342_CUBE_PATH="/disk-b/manga/data/v3_1_1/MaNGA_lin"
# @chiripa
# set IC342_CUBE_PATH="$LVM_DAP_PATH/_fitting-data/IC342/cubes"
# define output paths
set IC342_PROCESSED_PATH="$LVM_DAP_PATH/_fitting-data/IC342/preprocessed"
set IC342_OUTPUT_PATH="$LVM_DAP_PATH/_fitting-data/IC342/out"

# check if output path already exists
# if not, create it
if (! -d $IC342_PROCESSED_PATH) mkdir $IC342_PROCESSED_PATH
if (! -d $IC342_OUTPUT_PATH) mkdir $IC342_OUTPUT_PATH

# run manga preprocessing script
echo "starting preprocessing..."
preprocess-manga -r 2.5 -i $IC342_CUBE_PATH -o $IC342_PROCESSED_PATH -l $IC342_PROCESSED_PATH/IC342-cubes.txt
echo "preprocessing done"

# define analysis variables =======================================================================
set sigma_inst=0.001

# Velocity dispersion of the gas in AA
set sigma_gas=3.7
# ranges to be masked out from the analysis
set mask_list=None
# wavelength range for the non-linear parameter fitting
set nl_w_min=4700
set nl_w_max=6000
# wavelength range for the linear parameter fitting
set w_min=3700
set w_max=9500
# emission lines list to cross match with the autodetect algorithm
set elines_mask_file="$LVM_DAP_PATH/_fitting-data/_configs/MaNGA/emission_lines_long_list.txt"
# redshift grid
set z_guess=0.0001
set z_step=0
set z_min=-5
set z_max=5
# LOSVD grid
set s_guess=0
set s_step=0
set s_min=0
set s_max=350
# dust extinction in V-band grid
set d_guess=0
set d_step=0.1
set d_min=0
set d_max=2.5
# V-slice config
set v_slice_config="$LVM_DAP_PATH/_fitting-data/_configs/slice_V.conf"
# moment analysis
set momana_lines_list="$LVM_DAP_PATH/_fitting-data/_configs/MaNGA/emission_lines_momana_v2.txt"

# config tsp ======================================================================================
tsp -S 10
# start run with tsp ==============================================================================
set counter=0
echo "starting spectral fitting..."
foreach sed_file ( `ls $IC342_PROCESSED_PATH/CS.*.RSS.fits.gz` )
    # extract filename & define error file
    set filename=`basename $sed_file`
    set err_file="$IC342_PROCESSED_PATH/e_$filename"
    # remove CS. and .RSS.fits.gz from rss_file
    set label=`echo $filename | sed s/CS.//`
    set label=`echo $label | sed s/.RSS.fits.gz//`
    tsp -f lvm-dap $sed_file $rsp_models $sigma_inst $label --input-fmt rss --error-file $err_file --rsp-nl-file $rsp_nl_models --w-range $w_min $w_max --w-range-nl $nl_w_min $nl_w_max --redshift $z_guess $z_step $z_min $z_max --sigma $s_guess $s_step $s_min $s_max --AV $d_guess $d_step $d_min $d_max --sigma-gas $sigma_gas --emission-lines-file $elines_mask_file -c --output-path $IC342_OUTPUT_PATH
    
    # just for testing
    # @ counter=$counter + 1
    # if ( $counter == 1 ) break
end
echo "queue done"

echo "starting gas cube extraction..."
gas-cube-extractor -i $IC342_CUBE_PATH -p $IC342_PROCESSED_PATH -o $IC342_OUTPUT_PATH -n 1 -v --slice-config-file $v_slice_config --elines-list-file $momana_lines_list --overwrite
echo "extraction done"

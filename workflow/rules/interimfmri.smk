import json
import pandas as pd
from os.path import join


           
wildcard_constraints: 
    subject = '[a-zA-Z0-9]+',
    task = '[a-zA-Z0-9]+',
    site = '[a-zA-Z0-9]+',
    denoise = '[a-zA-Z0-9]+',
    space = '[a-zA-Z0-9]+',
    atlas = '[a-zA-Z0-9]+',
    fwhm = '[a-zA-Z0-9]+'

         
       



rule denoise:
    input: 
        nii = bids(root='results/{prepost}',subject='{subject}',site='{site}',task='{task}',space='{space}',desc='resampled',suffix='bold.nii.gz'),
        json = get_bold_json,
        confounds_tsv = lambda wildcards: config['preproc_confounds'][wildcards.prepost][wildcards.site],
        #use preop mask regardless of whether postop or preop (since will be resampled to preop space)
        mask_nii = bids(root='results/preop',subject='{subject}',site='{site}',task='{task}',space='{space}',desc='resampled',suffix='mask.nii.gz')
    params:
        denoise_params = lambda wildcards: config['denoise'][wildcards.denoise],
    output: 
        nii = bids(root='results/{prepost}',subject='{subject}',site='{site}',task='{task}',denoise='{denoise}',space='{space}',suffix='bold.nii.gz'),
        json = bids(root='results/{prepost}',subject='{subject}',site='{site}',task='{task}',denoise='{denoise}',space='{space}',suffix='bold.json')
    group: 'subj'
    script: '../scripts/denoise.py'

  
rule smooth:
    input:
        nii = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',suffix='bold.nii.gz'),
        json = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',suffix='bold.json')
    params:
        fwhm = lambda wildcards: float(wildcards.fwhm)
    output:
        nii = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',fwhm='{fwhm}',suffix='bold.nii.gz'),
        json = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',fwhm='{fwhm}',suffix='bold.json')
    group: 'subj'
    script: '../scripts/smooth.py'


rule schaefer_connectivity:
    input:
        nii = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',fwhm='{fwhm}',suffix='bold.nii.gz'),
    params:
        n_rois = 300,
        yeo_networks = 7,
        data_dir = 'resources',
        conn_measure = 'correlation'
    group: 'subj'
    output:
        txt = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',fwhm='{fwhm}',atlas='{atlas,schaefer}',suffix='conn.txt'),
        png = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',fwhm='{fwhm}',atlas='{atlas,schaefer}',suffix='conn.png'),
    script: '../scripts/connectivity_matrix.py'
    
rule schaefer_network:
    """ Uses the Schaefer connectivity and 7-network labels to construct 14x14 network connectivity matrices, by averaging values across the network parcels """
    input:
        conn_txt = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',fwhm='{fwhm}',atlas='{atlas,schaefer}',suffix='conn.txt'),
        network_txt = 'resources/schaefer_2018/Schaefer2018_300Parcels_7Networks_order.txt' #this should be downloaded when the prev rule is first run
    group: 'subj'
    output:
        txt = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',fwhm='{fwhm}',atlas='{atlas,schaefer}',network='Yeo7',suffix='conn.txt'),
        png = bids(root='results/{prepost}',site='{site}',subject='{subject}',task='{task}',denoise='{denoise}',space='{space}',fwhm='{fwhm}',atlas='{atlas,schaefer}',network='Yeo7',suffix='conn.png'),
    script: '../scripts/network_matrix.py'



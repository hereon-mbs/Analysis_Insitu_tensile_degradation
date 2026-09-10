# Analysis_Insitu_tensile_degradation
Analysis scripts of in situ tensile degradation experiments with µCT. Determined are stress-strain curves and 3D degradation parameter at different force steps.


**In situ tensile experiment analysis**

This analysis examines µCT scans obtained during degradation and tensile experiments at different load steps. The stress-strain curves are determined and corrected for waiting times, along with various degradation parameters from segmented µCT scans. 
The analysis is optimized for in situ tensile degradation experiments performed at the P05 beamline at DESY, Hamburg. For experiments at other beamlines/synchrotrons, the folder structure may differ and has to be adapted accordingly.

*Prerequisites:*

The script requires segmented µCT scans with material labels and, optionally, cracks and degradation.

*Procedure:*

1.	The main script is Insitu_strain_CT, which requires Insitu_strain_CT_single for the initial calculations.
2.	To be able to run the script for all applicable samples, they need to be defined in section Define samples in both Insitu_strain_CT and Insitu_strain_CT_single
3.	The script analysis all samples of the same strain rate and medium: for this, wanted_speed and wanted_medium have to be defined in the beginning
4.	It is possible to choose between two analysis methods:

    a.	Averaging over all samples of the same condition: At every stress step, all samples that were scanned at this stress are averaged. As the sample response can vary significantly, the calculated values show a high       error and are therefore difficult to interpret. This method is not recommended in most cases.

    b.	Plotting of all samples: all samples of the same condition are plotted individually. By this, the response is visible for each sample.
5.	If the defined sample is analyzed the first time, Insitu_strain_CT_single is run

    a.	This script can be run on its own; then the sample information have to be added manually
  	
    b.	The voxel size has to be adapted for correct calculations
  	
    c.	It is possible to select whether the results are plotted, exported and combined. To run the script for several samples, it is necessary to set exporting and combine to 1. If the export is deactivated, the                analysis is run every time, which is time consuming
  	
    d.	Required is the script contact_area [1]
  	
    e.	All results include the stress step at which the µCT scan was conducted
  	
    f.	Calculated are (further information given below):
       -	Material: volume
       -	Cracks: volume, surface area, length, portion of surface cracks
       -	Degradation: volume, surface area, layer thickness, degradation-to_crack contact, distance to surface
  	
*Calculated Parameters:*

-	Crack length: it is the length of the segmented cracks calculated by skeletonization of the crack segmentation and determination of the max geodesic distance of each crack path
-	Degradation layer thickness: (just approximation) all 3D degradation regions are determined, and the axis length of a fitted ellipsoid is calculated
-	degradation-to_crack contact: calculated is how much degradation surface is in contact with crack surface
-	Degradation distance to surface: the distance of the center of 3D degradation regions to the sample surface is calculated

**Stress-strain curves**

To plot the stress-strain curve of the in situ tensile experiment, the script Insitu_stress_strain_curve is needed. This calculates the curve by deleting waiting and scanning times.

*Procedure:*

1.	Similar to the previous scripts, the applicable samples have to be added in the Define sample section
2.	The script can be run for a single or multiple samples, which are then plotted in one graph
3.	Prior to running the script, the samples, beamtime, and year have to be defined 

**References**

[1] Julian Moosmann, https://github.com/moosmann/matlab/blob/master/matlab/utilities/contact_area.m

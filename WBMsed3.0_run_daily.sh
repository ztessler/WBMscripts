#!/bin/bash

if [ "${0%/*}" != "." ]; then PROJECTDIR="${0%/*}"; PROJECTDIR="${PROJECTDIR%/Scripts}"; else PROJECTDIR=".."; fi 
               SCRIPT="${0##*/}"; SCRIPT="${SCRIPT%.sh}";

GHAAS_DIR="/scratch/saco2635/Latest_version/ghaas"

      USAGE="Usage: <Domain> <Resolution> [dist|dist+gbc|prist|prist+gbc]"
      MODEL="${PROJECTDIR}/Model/WBMplus/bin/wbmplus.bin"
RGISARCHIVE="/scratch/ccny/RGISarchive"
  RGISPILOT="/scratch/ccny/RGISpilot"
RGISRESULTS="${PROJECTDIR}/RGISresults" # $(date '+%Y-%m-%d')
 RGISBINDIR="${GHAAS_DIR}/bin"
 RGISCSDMS="/scratch/saco2635/RGISarchiveCSDMS" # New input directory for WBMsed

source "${GHAAS_DIR}/Scripts/RGISfunctions.sh"
#source "${PROJECTDIR}/Model/MFlib/Scripts/fwFunctions20_3multi_postproc.sh"
source "${PROJECTDIR}/Model/MFlib/Scripts/fwFunctions20.sh"
       DOMAIN="${1}"; shift
   RESOLUTION="${1}"; shift
CONFIGURATION="${1}"; shift
MEANINPUTS="${PROJECTDIR}/BQARTmeanInputs"
  EXPERIMENT="Bankfull3.0-Qbf-n0.75"

             STARTYEAR=2002
               ENDYEAR=2010

        AIRTEMP_STATIC=$(RGISfile "${RGISARCHIVE}" "${DOMAIN}+" "air_temperature"              "NCEP"           "${RESOLUTION}+" "TS" "daily"   "1948")
       AIRTEMP_DYNAMIC=$(RGISfile "${RGISARCHIVE}" "${DOMAIN}+" "air_temperature"              "NCEP"           "${RESOLUTION}+" "TS" "daily"   "xxxx")
 MONTHLY_PRECIP_STATIC=$(RGISfile "${RGISARCHIVE}" "${DOMAIN}+" "precipitation"                "GPCCfull"       "${RESOLUTION}+" "TS" "monthly" "1948")
MONTHLY_PRECIP_DYNAMIC=$(RGISfile "${RGISARCHIVE}" "${DOMAIN}+" "precipitation"                "GPCCfull"       "${RESOLUTION}+" "TS" "monthly" "xxxx")
    PRECIP_FRAC_STATIC=$(RGISfile "${RGISARCHIVE}" "${DOMAIN}+" "daily_precipitation_fraction" "NCEP"           "${RESOLUTION}+" "TS" "daily"   "1948")
   PRECIP_FRAC_DYNAMIC=$(RGISfile "${RGISARCHIVE}" "${DOMAIN}+" "daily_precipitation_fraction" "NCEP"           "${RESOLUTION}+" "TS" "daily"   "xxxx")

case ${CONFIGURATION} in
	(dist|dist+gbc)
		DISTURBED="on"
		EXPERIMENT="${EXPERIMENT}+Dist"
	;;
	(prist|prist+gbc)
		DISTURBED="off"
		EXPERIMENT="${EXPERIMENT}+Prist"
	;;
	(*)
		echo "${USAGE}"
		exit 1
	;;
esac
case ${CONFIGURATION} in
	(dist+gbc|prist+gbc)
		GBC="on"
		EXPERIMENT="${EXPERIMENT}+GBC"
	;;
	(dist|prist)
		GBC="off"
	;;
	(*)
		echo "${USAGE}"
		exit 1
	;;
esac
case ${RESOLUTION} in
	(30min)
	           NETVERSION="PotSTNv602"
	;;
	(06min)
	       #  NETVERSION="HydroSHEDSv110" #changed for NAmerica run
	         NETVERSION="STN+HydroSHEDS" #changed for Global 6min run 
	         #  NETVERSION="HydroSHEDS-STNv100" # changed for testing 22/11/2010
		   #NETVERSION="PotSTNv120"
	;;
	(*)
		echo "${USAGE}"
		exit 1
		;;
esac

NETWORK=$(RGISfile ${RGISARCHIVE} ${DOMAIN} network ${NETVERSION} ${RESOLUTION} static)

                IRRMAP="FAO"
              CROPFILE="${PROJECTDIR}/ASCII/Cropfile_FourCrops_2008-06-07.txt"

echo "Configuration: ${PROJECTDIR} ${SCRIPT} ${EXPERIMENT} ${RESOLUTION} ${STARTYEAR} ${ENDYEAR}"

FwArguments -s on -f on -u on -n 2 -D on  $* || exit -1  

FwInit    "${MODEL}" "${DOMAIN}" "${NETWORK}" "${PROJECTDIR}/GDS" "${RGISRESULTS}" "${RGISBINDIR}" || exit -1 

(( DataNum = 0 ))
DATASOURCES[${DataNum}]="AirTemperature                static  Common        file  ${AIRTEMP_STATIC}";                                                                                           (( ++DataNum ))
DATASOURCES[${DataNum}]="AirTemperature                dynamic Common        file  ${AIRTEMP_DYNAMIC}";                                                                                          (( ++DataNum ))
DATASOURCES[${DataNum}]="FieldCapacity                 static  Common        file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ field_capacity              WBM         ${RESOLUTION}+ static)";         (( ++DataNum ))

DATASOURCES[${DataNum}]="MonthlyPrecipitation          static  Common        file  ${MONTHLY_PRECIP_STATIC}";                                                                                    (( ++DataNum ))
DATASOURCES[${DataNum}]="MonthlyPrecipitation          dynamic Common        file  ${MONTHLY_PRECIP_DYNAMIC}";                                                                                   (( ++DataNum ))
DATASOURCES[${DataNum}]="PrecipitationFraction         static  Common        file  ${PRECIP_FRAC_STATIC}";                                                                                       (( ++DataNum ))
DATASOURCES[${DataNum}]="PrecipitationFraction         dynamic Common        file  ${PRECIP_FRAC_DYNAMIC}";                                                                                      (( ++DataNum ))

DATASOURCES[${DataNum}]="RicePondingDepth              static  Common        const 50";                                                                                                          (( ++DataNum ))
DATASOURCES[${DataNum}]="RiverbedSlope                 static  Common        const 0.10";                                                                                                        (( ++DataNum ))
DATASOURCES[${DataNum}]="RootingDepth                  static  Common        file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ rooting_depth               WBM         ${RESOLUTION}+ static)";         (( ++DataNum ))
DATASOURCES[${DataNum}]="WiltingPoint                  static  Common        file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ wilting_point               WBM         ${RESOLUTION}+ static)";         (( ++DataNum ))

DATASOURCES[${DataNum}]="GrowingSeason1_Start          static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ growing_season1    Computed-CRU+FAO     ${RESOLUTION}+ LT annual)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="GrowingSeason2_Start          static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ growing_season2    Computed-CRU+FAO     ${RESOLUTION}+ LT annual)";      (( ++DataNum ))

DATASOURCES[${DataNum}]="IrrigatedAreaFraction         static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ irrigated_area_fraction     GMIA        ${RESOLUTION}+ LT annual 2008)"; (( ++DataNum ))
DATASOURCES[${DataNum}]="IrrigatedAreaFraction         dynamic Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ irrigated_area_fraction     GMIA        ${RESOLUTION}+ TS annual xxxx)"; (( ++DataNum ))
DATASOURCES[${DataNum}]="IrrigationIntensity           static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ cropping_intensity          DWisser     ${RESOLUTION}+ LT annual)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="IrrigationEfficiency          static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ irrigation_efficiency       DWisser     ${RESOLUTION}+ LT annual)";      (( ++DataNum ))

DATASOURCES[${DataNum}]="ReservoirCapacity             static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ reservoir_capacity          UNH661      ${RESOLUTION}+ LT annual 2008)"; (( ++DataNum ))
DATASOURCES[${DataNum}]="ReservoirCapacity             dynamic Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ reservoir_capacity          UNH661      ${RESOLUTION}+ TS annual xxxx)"; (( ++DataNum ))
DATASOURCES[${DataNum}]="RicePercolationRate           static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ rice_percolation_rate       DWisser     ${RESOLUTION}+ LT annual)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="SmallReservoirStorageFraction static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ small_reservoir_coefficient GMIAderived ${RESOLUTION}+ LT annual 2008)"; (( ++DataNum ))
DATASOURCES[${DataNum}]="SmallReservoirStorageFraction dynamic Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ small_reservoir_coefficient GMIAderived ${RESOLUTION}+ TS annual xxxx)"; (( ++DataNum ))

DATASOURCES[${DataNum}]="CropFraction_01               static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ perennial_crop_fraction     SAGE        ${RESOLUTION}+ LT annual)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="CropFraction_02               static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ vegetables_crop_fraction    SAGE        ${RESOLUTION}+ LT annual)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="CropFraction_03               static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ other_crop_fraction         SAGE        ${RESOLUTION}+ LT annual)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="CropFraction_04               static  Disturbed     file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ rice_crop_fraction          SAGE        ${RESOLUTION}+ LT annual)";       (( ++DataNum ))


#DATASOURCES[${DataNum}]="ContributingArea    			static  Common       file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ contributing_area    ETOPO1 ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="ReliefMax    					static  Common       file  $(RGISfile ${RGISCSDMS} ${DOMAIN}+ relief_max    ETOPO1 ${RESOLUTION}+ static)";      		(( ++DataNum ))
DATASOURCES[${DataNum}]="IceCover    					static  Common       file  $(RGISfile ${RGISCSDMS} ${DOMAIN}+ ice_cover    ICE5Gv102 ${RESOLUTION}+ static)";      		(( ++DataNum ))
DATASOURCES[${DataNum}]="TimeSteps    					static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ time_steps  BQART ${RESOLUTION}+ static)";      		(( ++DataNum ))
DATASOURCES[${DataNum}]="AirTempAcc_time    			static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ temperature_accumulation  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="DischargeAcc    				static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ discharge_accumulation  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BQART_GNP    					static  Common       file  $(RGISfile ${RGISCSDMS} ${DOMAIN}+ bqart_gnp    BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BQART_Lithology   				static  Common       file  $(RGISfile ${RGISCSDMS} ${DOMAIN}+ bqart_lithology    BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="Population  					static  Common       file  $(RGISfile ${RGISARCHIVE} ${DOMAIN}+ population    HYDE-CIESIN ${RESOLUTION}+ TS annual 1960-2015)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="Slope-Min  					static  Common       file  $(RGISfile ${RGISCSDMS} ${DOMAIN}+ slope_min   ETOPO1bed ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BankfullQ2    					static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ bankfull_q2  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BankfullQ5    					static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ bankfull_q5  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BankfullQ10   					static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ bankfull_q10  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BankfullQ25   					static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ bankfull_q25  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BankfullQ50   					static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ bankfull_q50  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BankfullQ100   				static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ bankfull_q100  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="BankfullQ200   				static  Common       file  $(RGISfile ${MEANINPUTS} ${DOMAIN}+ bankfull_q200  BQART ${RESOLUTION}+ static)";      (( ++DataNum ))
DATASOURCES[${DataNum}]="Bankfull_Qn                	static  Common       const 0";  (( ++DataNum )) #define the reacurance bankfull discharge (2, 10, 25, 50, 100, 200 years), 0 for a different source 
DATASOURCES[${DataNum}]="FlowCoefficient              	static  Common       const 0.75"; (( ++DataNum )) #define the return flow (from floodplain to the river) coefficient
DATASOURCES[${DataNum}]="BankfullQ    					static  Common       file  $(RGISfile ${RGISCSDMS} ${DOMAIN}+ bankfull_q  STN+HydroSHEDS ${RESOLUTION}+ static)";      (( ++DataNum ))


(( OptNum  = 0 ))
OPTIONS[${OptNum}]="CropParameterFileName   ${CROPFILE}";       (( ++OptNum ))
OPTIONS[${OptNum}]="Model                   sedimentflux";      (( ++OptNum )) #changed from "balance" (S.C) then from "sedimentflux" then from "BQARTinputs" (8/9/10) then from "sedimentflux" (5/11/10)
OPTIONS[${OptNum}]="Discharge               calculate";         (( ++OptNum ))
OPTIONS[${OptNum}]="DischargeMean           calculate";         (( ++OptNum ))
OPTIONS[${OptNum}]="DoubleCropping          FirstSeason";       (( ++OptNum ))
OPTIONS[${OptNum}]="GroundWaterBETA         0.01666667";        (( ++OptNum ))
OPTIONS[${OptNum}]="InfiltrationFraction    0.5";               (( ++OptNum ))
OPTIONS[${OptNum}]="Muskingum               static";            (( ++OptNum ))
OPTIONS[${OptNum}]="Precipitation           fraction";          (( ++OptNum )) #changed
OPTIONS[${OptNum}]="RainInterception        none";              (( ++OptNum ))
OPTIONS[${OptNum}]="RainInfiltration        simple";            (( ++OptNum ))
OPTIONS[${OptNum}]="RainPET                 Hamon";             (( ++OptNum ))
OPTIONS[${OptNum}]="Riverbed                slope-independent"; (( ++OptNum ))
OPTIONS[${OptNum}]="Routing                 muskingum";         (( ++OptNum ))
OPTIONS[${OptNum}]="Runoff                  calculate";         (( ++OptNum ))
OPTIONS[${OptNum}]="RunoffVolume            calculate";         (( ++OptNum ))
OPTIONS[${OptNum}]="SoilMoisture            bucket";            (( ++OptNum ))
OPTIONS[${OptNum}]="SoilTemperature         none";              (( ++OptNum ))
OPTIONS[${OptNum}]="SoilMoistureALPHA       5.0";               (( ++OptNum ))
OPTIONS[${OptNum}]="SoilWaterCapacity       calculate";         (( ++OptNum ))
OPTIONS[${OptNum}]="WetlandAreaFraction     none";              (( ++OptNum ))
OPTIONS[${OptNum}]="SedimentFlux      	    calculate";         (( ++OptNum )) #new !!!! (S.C)
OPTIONS[${OptNum}]="BedloadFlux      	    calculate";         (( ++OptNum )) #new !!!! (S.C)

(( OutNum  = 0 ))
OUTPUTS[${OutNum}]="Discharge";                                 (( ++OutNum ))
#OUTPUTS[${OutNum}]="Evapotranspiration";                        (( ++OutNum ))
#OUTPUTS[${OutNum}]="GroundWaterChange";                         (( ++OutNum ))
#OUTPUTS[${OutNum}]="RainPET";                                   (( ++OutNum ))
#OUTPUTS[${OutNum}]="Runoff";                                    (( ++OutNum ))
#OUTPUTS[${OutNum}]="SnowPackChange";                            (( ++OutNum ))
#OUTPUTS[${OutNum}]="SoilMoisture";                              (( ++OutNum ))
#OUTPUTS[${OutNum}]="SoilMoistureChange";                        (( ++OutNum ))
#OUTPUTS[${OutNum}]="RelativeSoilMoisture";                      (( ++OutNum ))
#OUTPUTS[${OutNum}]="SurfaceRunoff";                             (( ++OutNum ))
#OUTPUTS[${OutNum}]="WaterBalance";                              (( ++OutNum ))
#OUTPUTS[${OutNum}]="SedimentFlux";                              (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="LithologyMean";                              (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="BQART_A";                          (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="BQART_B";                              (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="BQART_R";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="BQART_T";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="BQART_Qbar_m3s";					(( ++OutNum ))
#OUTPUTS[${OutNum}]="BQART_Qbar_km3y";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="NewDischargeAcc";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="NewAirTempAcc_time";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="AirTempAcc_space"; 						(( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="NewTimeSteps";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="PopulationAcc";                          (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="PopulationDensity";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="GNPAreaAcc";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="MeanGNP";           		                (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="BQART_Eh";   					 (( ++OutNum ))
#OUTPUTS[${OutNum}]="BQART_Te";   					 (( ++OutNum ))
#OUTPUTS[${OutNum}]="Qs_bar";   						 (( ++OutNum ))
#OUTPUTS[${OutNum}]="TeAacc";   					 (( ++OutNum ))
#OUTPUTS[${OutNum}]="ResStorageAcc";					 (( ++OutNum ))
#OUTPUTS[${OutNum}]="DischargeMean";					 (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="BedloadFlux";					 (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="DeltaBedload";					 (( ++OutNum )) #NEW !!!!!!! (S.C)
#OUTPUTS[${OutNum}]="DeltaQs";					 (( ++OutNum )) #NEW !!!!!!! (S.C)
OUTPUTS[${OutNum}]="OverBankQ";					 (( ++OutNum )) #NEW !!!!!!! (S.C)

if [[ "${DISTURBED}" == "on" ]]
then
	OPTIONS[${OptNum}]="IrrigatedAreaMap        ${IRRMAP}";      (( ++OptNum ))
	OPTIONS[${OptNum}]="Irrigation              calculate";      (( ++OptNum ))
	OPTIONS[${OptNum}]="IrrReferenceETP         Hamon";          (( ++OptNum ))
	OPTIONS[${OptNum}]="IrrUptakeRiver          calculate";      (( ++OptNum ))
	OPTIONS[${OptNum}]="IrrUptakeGrdWater       calculate";      (( ++OptNum ))
	OPTIONS[${OptNum}]="Reservoirs              calculate";      (( ++OptNum ))
	OPTIONS[${OptNum}]="SmallReservoirCapacity  calculate";      (( ++OptNum ))

	#OUTPUTS[${OutNum}]="IrrGrossDemand";                         (( ++OutNum ))
	#OUTPUTS[${OutNum}]="IrrReturnFlow";                          (( ++OutNum ))
	#OUTPUTS[${OutNum}]="IrrUptakeExcess";                        (( ++OutNum ))
	#OUTPUTS[${OutNum}]="IrrUptakeExternal";                      (( ++OutNum ))
	#OUTPUTS[${OutNum}]="IrrUptakeGroundWater";                   (( ++OutNum ))
	#OUTPUTS[${OutNum}]="IrrUptakeRiver";                         (( ++OutNum ))
	#OUTPUTS[${OutNum}]="ReservoirStorage";                       (( ++OutNum ))

	#OUTPUTS[${OutNum}]="SmallReservoirStorage";                  (( ++OutNum ))
	#OUTPUTS[${OutNum}]="SmallReservoirStorageChange";            (( ++OutNum ))
	#OUTPUTS[${OutNum}]="SmallReservoirCapacity";                 (( ++OutNum ))
	#OUTPUTS[${OutNum}]="IrrUptakeBalance";                       (( ++OutNum ))
	#OUTPUTS[${OutNum}]="IrrWaterBalance";                        (( ++OutNum ))
else
	OPTIONS[${OptNum}]="Irrigation              none";           (( ++OptNum ))
	OPTIONS[${OptNum}]="Reservoirs              none";           (( ++OptNum ))
fi

echo "entering FwDataSrc"
FwDataSrc     "${DATASOURCES[@]}" || exit -1
echo "Exited FwDataSrc. "
#read
echo "entering FwOptions"
#echo "OPTIONS array: " ${OPTIONS[@]}
FwOptions         "${OPTIONS[@]}" || exit -1 
echo "Exited FwOptions. "
#read
echo "entering FwOutputs"
#echo "OUTPUT array: " ${OUTPUTS[@]}
FwOutputs         "${OUTPUTS[@]}" || exit -1
echo "Exited FwOutputs."
#read
echo "entering FwRun"
FwRun  "${EXPERIMENT}" "${STARTYEAR}" "${ENDYEAR}" || exit -1

echo "Converting output files to NetCDF"
./rgis2netcdf.sh ../RGISresults/ ../RGISresults/
#./rgisDelete.sh ${RGISRESULTS} ${RGISRESULTS}

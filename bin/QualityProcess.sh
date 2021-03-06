#! /bin/bash
# QualityProcess.sh
# Geoffrey Hannigan
# Pat Schloss Lab
# University of Michigan

##################
# Set Script Env #
##################

# Set the variables to be used in this script
export Inputfile=$1
export MappingFile=$2
export Outputfilename=$3

# Dependencies
export DeconsSeq=/nfs/turbo/pschloss/bin/deconseq-standalone-0.4.3/deconseq.pl
export fastx=/nfs/turbo/pschloss/bin/fastx_0.0.13_precompiled/fastq_quality_trimmer
export CutAdapt=/nfs/turbo/pschloss/bin/cutadapt-1.9.1/bin/cutadapt

###################
# Set Subroutines #
###################
# Some of these look simple, but this is an easy way to ensure the parameters are standardized
# across multiple calls of all subroutines.

runCutadaptWithMap () {
	echo Input fastq = "${1}" #1 = full path to fastq file to be trimmed
	echo Mapping file = "${2}" #2 = full path to mapping file mapping file
	echo Output file = "${3}" #3 = full path for output directory
	export SAMPLEID=$(echo ${1} | sed 's/_R.*//g' | sed 's/.*\///g')
	export THREEPRIME=$(awk --assign sampleid="$SAMPLEID" '$2 == sampleid { print $19 }' ${2})
	export FIVEPRIME=$(awk --assign sampleid=$SAMPLEID '$2 == sampleid { print $16 }' ${2})
	echo Sample ID is ${SAMPLEID}...
	echo 3-prime adapter is ${THREEPRIME}...
	echo 5-prime adapter is ${FIVEPRIME}...
	python2.7 "${CutAdapt}" --error-rate=0.1 --overlap=10 -a ${THREEPRIME} -a ${FIVEPRIME} ${1} > ${3}
}

runFastx () {
	${fastx} -t 33 -Q 30 -l 75 -i "${1}" -o "${2}"
}

# Export functions
export -f runCutadaptWithMap
export -f runFastx

############
# Run Data #
############
# Decompress file
echo PROGRESS: Decompressing file
gunzip ${Inputfile}
export Uncompressedfilename=$(echo ${Inputfile} | sed 's/.gz//')
echo PROGRESS: Uncompressed file name is ${Uncompressedfilename}

echo PROGRESS: Cutting adapters
runCutadaptWithMap \
	${Uncompressedfilename} \
	${MappingFile} \
	${Uncompressedfilename}.cutadapt

echo PROGRESS: Quality trimming reads
runFastx \
	${Uncompressedfilename}.cutadapt \
	${Outputfilename}

echo PROGRESS: Cleaning up directory
rm ${Uncompressedfilename}.cutadapt

#!/bin/bash

#module load gi/star/2.3.0e
module load gi/samtools/1.0
module load gi/novosort/precompiled/1.03.08
module load nenbar/star/2.4.0d
module load gi/gcc/4.8.2

numcores=12
tag="-P DSGClinicalGenomics"


#directory hierarchy
#raw files directory
homedir="/share/ScratchGeneral/nenbar"
projectDir="$homedir/projects/Alex"
resultsDir="$projectDir/project_results/"

genomeDir="/share/ClusterShare/biodata/contrib/nenbar/genomes/star/FVB"
#genomeDir="/share/ClusterShare/biodata/contrib/nenbar/genomes/star/mm10_sequin"
#extension of the files to be used
inExt="fastq.gz"

#scripts directory
scriptsPath="/share/ScratchGeneral/nenbar/projects/Alex/scripts"
logDir=$scriptsPath"/logs"

#name to append to projectname and create a folder
inType="trimgalore"

projectnames=( "BAC" )

for projectname in ${projectnames[@]}; do


        #out directory
        
        inPath="$homedir/projects/Alex/project_results/$projectname.$inType/"

	outPath="/share/ScratchGeneral/nenbar/projects/Alex/project_results/$projectname.star"
        #log and command files for bsub
        logPath="logs"
        commandPath="commands"
        #make the directory structure   
        mkdir -p $outPath
        mkdir -p $logPath
        mkdir -p $commandPath

        rm -f $commandFile

        
        #echo Reading files from $sampleFile
        if [[ ! (-f $sampleFile) ]]; then
                echo The file with the list of samples $sampleFile does not exist
        fi

        subs=0

        #get the name of the script for the logs
        scriptName=`basename $0`
        i=0
        echo $inPath
	files=`ls $inPath`
        for file in ${files[@]};do
                        echo The file used is: $file
                        filesTotal[i]=$file;
                        let i++;
        done 
done;

j=0
echo ${#filesTotal[@]}
while [ $j -lt ${#filesTotal[@]} ]; do

        dir=`echo ${filesTotal[$j]}`
        files=`ls $inPath/$dir/*.$inExt`
	
	inFile1=${files[0]}
	uniqueID=`basename $dir`
        name=$uniqueID
        outDir=$outPath/$uniqueID/
	mkdir -p $outDir
        echo $name
	#echo $command_line


	starJobName="star."$name
	samSortJobName="samSort"$name
	bamJobName="bam."$name
	sortJobName="sort."$name
	
	indexJobName="index."$name
	indexStatsJobName="indexstats."$name
	outSam=$outDir"Aligned.out.sam"
	outSortedSam=$outDir"Aligned.sorted.sam"
	outBam=$outDir"$name.bam"
	outSortedBam=$outDir"$name.sorted.bam"

	#star_line="/home/nenbar/local/lib/STAR-STAR_2.4.0i/source/STAR --genomeDir $genomeDir --runMode alignReads --readFilesIn $inFile1 $inFile2 --outFileNamePrefix $outDir --runThreadN 4 --outSAMattributes Standard --outSAMstrandField intronMotif --sjdbOverhang 99" 
	
	star_line="
        /home/nenbar/local/lib/STAR/bin/Linux_x86_64/STAR --runMode alignReads \
     --genomeDir $genomeDir \
     --readFilesCommand zcat \
     --outFileNamePrefix $outDir \
     --outFilterType BySJout \
     --outSAMattributes NH HI AS NM MD\
     --outFilterMultimapNmax 20 \
     --outFilterMismatchNmax 999 \
     --outFilterMismatchNoverReadLmax 0.04 \
     --alignIntronMin 20 \
     --alignIntronMax 1500000 \
     --alignMatesGapMax 1500000 \
     --alignSJoverhangMin 6 \
     --alignSJDBoverhangMin 1 \
     --readFilesIn $inFile1 \
     --runThreadN $numcores \
     --outFilterMatchNmin 40 \
     --outSAMtype BAM Unsorted \
     --limitBAMsortRAM 80000000000"

        #--outStd BAM_Quant | samtools view -f 3 -u - | novosort -c $numcores -n -m 16G -o $outSortedBam -"
	#bam_line="samtools view -m 16G -h -S $outSam -b -o $outBam"
	samtools_line="samtools view -f 3 -u Aligned.toTranscriptome.out.bam -o $outDir$name.sorted"
        sort_line="novosort -n -m 16G -o $outSortedBam"

        #echo $star_line
        qsubLine="qsub -q short.q -b y -wd $logDir -j y -R y -pe smp $numcores $tag -V"
        #echo "samtools index $outSortedBam"
        
        $qsubLine -N $starJobName $star_line 
	$qsubLine -N $bamJobName -hold_jid $starJobName $samtools_line 
	$qsubLine -N $sortJobName -hold_jid $bamJobName $sort_line 
        
        j=$(($j+1))


done;
#        --outWigType wiggle \
# \
#        --outStd BAM_Quant | samtools view -f 3 -u - | novosort -n -m 16G -o output.bam -
#qsub -q short.q -b y -wd $logDir -j y -R y -pe smp $numcoresSmall $tag -V
#        --outSAMtype BAM Unsorted \
#-outStd BAM_Quant | samtools view -f 3 -u - | novosort -c $numcores -n -m 16G -o $outSortedBam -"


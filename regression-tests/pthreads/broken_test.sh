#!/bin/bash
echo 'testing Graphlet (not orbit) Degree Vectors [MULTITHREADED]'

# "correct" values came from 3e9 samples... but we no longer need to divide by 1000 since it's already absolute estimates

N=9000000

BLANT_HOME=`/bin/pwd`
LIBWAYNE_HOME="$BLANT_HOME/libwayne"
PATH="$BLANT_HOME:$BLANT_HOME/scripts:$BLANT_HOME/libwayne/bin:$PATH"
CORES=16

echo "Starting continuous test loop..."

while true; do
echo "---------------------------------------------------"

# main script code, from test2_GDV.sh
export k=1
for S in NBE EBE; do
    case $S in
    MCMC) TOL=0.006; exp=2;;
    SEC)  TOL=1.1e-4; exp=3;;
    NBE)  TOL=1.1e-4; exp=3;;
    EBE)  TOL=1.5e-4; exp=3;;
    esac

    for k in 3 4 5 6 7
    do
	CORRECT=regression-tests/0-sanity/syeast.$S.gdv.abs.3e9.k$k.txt.xz
    for t in $CORES; do
        if [ -f canon_maps/canon_map$k.bin -a -f $CORRECT ]; then
            /bin/echo -n "$S:$k:$t "
            ./blant -q -R -s $S -mg -n $N -k $k -t $CORES networks/syeast.el |
            sort -n | cut -d' ' -f2- |
            paste - <(unxz < $CORRECT) |
            tee "raw$S:$k.log" |
            awk '{
                cols=NF/2;
                for(c1=1; c1<=cols; c1++){
                    c2=cols+c1;
                    if($c1 && $c2) {
                        ratio = $c1 / $c2;
                        printf "%.6g ", ratio;  # prints ratio with space, adjust format as needed
                    }
                }
                printf "\n";
            }' |
            tee "ratios$S:$k.log" |
            $LIBWAYNE_HOME/bin/stats -g | # the -g option means "geometric mean"
            sed -e 's/#/num/' -e 's/[	 ][	 ]*/ /g' |
            $LIBWAYNE_HOME/bin/named-next-col '
                BEGIN{k='$k'}
                {
                diff=ABS(1-mean)/(k*stdDev)^'$exp';
                if(diff > '"$TOL"') {
                    printf "BEYOND TOLERANCE: %g\n%s\n", diff, $0;
                    exit 1
                } else
                    printf "diff %.4e\t%s\n", diff, $0;
                }' # || exit 1

            # cat raw.log 1>&2
            # cat ratios.log 1>&2
        fi
    done # || exit 1
    done # || exit 1
done  # || exit 1


echo "Restarting..."

done
echo "Script failed. Exiting loop."

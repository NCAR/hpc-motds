#!/bin/bash -l

#----------------------------------------------------------------------------
# environment & site config, if any
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
#----------------------------------------------------------------------------

cd ${SCRIPTDIR} || { echo "cannot cd ${SCRIPTDIR}!!"; exit 1; }

#--------------------------------------------------------------
LOCK=$(pwd)/.motd_update.lock
remove_lock()
{
    rm -f "${LOCK}"
}

another_instance()
{
    echo "Cannot acquire lock on ${LOCK}"
    echo "There is another instance running, exiting"
    exit 1
}

have_lockfile=False
which lockfile >/dev/null 2>&1 && have_lockfile=True
if [[ True == ${have_lockfile} ]]; then
    lockfile -r 5 -l 120 "${LOCK}" || another_instance
    trap remove_lock EXIT
fi
#--------------------------------------------------------------


#--------------------------------------------------------------
timestamp="$(date +%F@%H:%M)"
cron_logdir="${HOME}/.my_cron_logs/$(date +%Y)/$(date +%m)"
logfile="${cron_logdir}/sync_motds_to_github.log"
mkdir -p ${cron_logdir} || exit 1
echo "[${timestamp}]: Running ${0} on $(hostname) from $(pwd)" \
    | tee -a ${logfile}
#--------------------------------------------------------------



start=$(date +%s)

which git >/dev/null 2>&1 || PATH=/glade/u/apps/casper/23.10/opt/view/bin:${PATH}

git add */latest 2>&1 | tee -a ${logfile}

git status */latest 2>&1 | grep "nothing to commit, working tree clean" >/dev/null 2>&1 \
    && { echo "No changes to push, exiting..." | tee -a ${logfile}; exit 0; }

git commit -m "[${0}] adding MOTD entries from $(pwd) on $(date)" 2>&1 | tee -a ${logfile}

git push 2>&1 | tee -a ${logfile} || { echo "cannot push to github.com on $(date), skipping update!"; exit 1; }

make -s -C .. fixperms

stop=$(date +%s)
elapsed=$((${stop} - ${start}))
echo "Done at $(date) / ${elapsed} second(s)" | tee -a ${logfile} 

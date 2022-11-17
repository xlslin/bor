#!/bin/bash
set -e

balanceInit=$(docker exec bor0 bash -c "bor attach /root/.bor/data/bor.ipc -exec 'Math.round(web3.fromWei(eth.getBalance(eth.accounts[0])))'")

#delay=600
#echo "Wait ${delay} seconds for state-sync..."
#sleep $delay
stateSyncFound="false"
checkpointFound="false"

while true
do
  
    balance=$(docker exec bor0 bash -c "bor attach /root/.bor/data/bor.ipc -exec 'Math.round(web3.fromWei(eth.getBalance(eth.accounts[0])))'")

    if ! [[ "$balance" =~ ^[0-9]+$ ]]; then
        echo "Something is wrong! Can't find the balance of first account in bor network."
        exit 1
    fi

    echo "Found matic balance on account[0]: " $balance

    if (( $balance <= $balanceInit )); then
        echo "Balance in bor network has not increased. Waiting for state sync..."
        #exit 1
    else
        echo "State Sync occured!"
        stateSyncFound="true"   
    fi

    checkpointID=$(curl -sL http://localhost:1317/checkpoints/latest | jq .result.id)

    if [ $checkpointID == "null" ]; then
        echo "Checkpoint didn't arrive yet! Waiting..."
        #exit 1
    else
        echo "Found checkpoint ID:" $checkpointID
        checkpointFound="true"
    fi

    if (( $stateSyncFound == "true" && $checkpointFound == "true" )); then
        break
    fi    

done
echo "All tests have passed!"

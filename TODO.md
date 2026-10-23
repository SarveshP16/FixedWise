# TODO

## Form 15G/15H tracking
Record per holder, per bank, per financial year whether Form 15G/15H was
submitted, so the Tax & TDS screen can show "no TDS expected" instead of an
estimate.

## PAN on record per holder
TDS is 20% instead of 10% when the bank has no PAN. A simple "PAN linked"
flag per holder would make the TDS estimate exact.

## Monthly-payout discounting
Banks pay slightly less than rate/12 on monthly-payout FDs (the quarterly
interest discounted to monthly). Currently shown as plain rate/12.

## Encrypted backups
Optional password for exported/auto-backup JSON files, since a synced
folder may be readable by other apps or services.

## Edit an existing deposit
Today a deposit can only be created, renewed, closed or deleted.

## Swipe actions on deposit cards
Swipe a card in the Deposits list to Close early / Delete, instead of always
opening the detail screen first.

#!/bin/sh
# Created by John Watson john@dctrwatson.com
# Last update: 10-13-2010
# Version: 01.00.00

################################################################################
# Copyright 2010 John Watson. All rights reserved. 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution. 

# THIS SOFTWARE IS PROVIDED BY JOHN WATSON AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL JOHN WATSON OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are
# those of the authors and should not be interpreted as representing official
# policies, either expressed or implied, of John Watson.
################################################################################

print_usage()
{
    echo "Usage: `basename $0` [-f FILE] [-k KEYFILE] [-p KEYFILE] [-e] [-d] [file]"
    echo
    echo "Uses a 32 character random string to symmetrically encrypt the file. This password string"
    echo "is then encrypted using the RSA key provided. A new random password string is"
    echo "generated every time the file is encrypted."
    echo
    echo -e "\t-f\tEncrypted file to be opened with \$EDITOR (Default: ~/.myvault)"
    echo -e "\t-k\tPrivate key file (Default: ~/.ssh/id_rsa)"
    echo -e "\t-p\tPublic key file (Default: {PRIVATE_KEYFILE}.pub.pem)"
    echo -e "\t-e\tEncrypt [file] to stdout"
    echo -e "\t-d\tDescrypt [file] to stdout"
    echo
    echo "If -e or -d is used, \$EDITOR will not be used to open the file defined by -f"
}

while getopts "f:k:p:deh" OPT ; do
    case $OPT in
        f)
        VFILE=$OPTARG 
        ;;
        k)
        PRIVKEY=$OPTARG
        ;;
        p)
        PUBKEY=$OPTARG
        ;;
        e)
        ENCRYPT=1
        ;;
        d)
        DECRYPT=1
        ;;
        h)
        print_usage
        exit 0
        ;;
    esac
done

shift $(($OPTIND - 1))

VFILE=${VFILE:-"$HOME/.myvault"}

PRIVKEY=${PRIVKEY:-"$HOME/.ssh/id_rsa"}
PUBKEY=${PUBKEY:-"$PRIVKEY.pub.pem"}

if [ ! -r $PRIVKEY ] ; then
    echo "Can not read the private key: $PRIVKEY"
    exit 1
fi

if [ -z $ENCRYPT ] && [ -z $DECRYPT ] ; then
    if [ ! -f $VFILE ] ; then
        touch $VFILE
        chmod 600 $VFILE
    elif [ ! -r $VFILE ] || [ ! -w $VFILE ] ; then
        echo "Need rw permissions on: $VFILE"
        ERR=1
    fi
else
    VFILE=$1
    if [ ! -z $DECRYPT ] && [ ! -r $VFILE ] ; then
        echo "No read permissions on: $VFILE"
        ERR=1
    fi
fi

if [ ! -f $PUBKEY ] ; then
    echo "Creating public key: $PUBKEY"
    openssl rsa -in $PRIVKEY -pubout -out $PUBKEY
fi

if [ ! -r $PUBKEY ] ; then
    echo "Can not read the public key: $PUBKEY"
    ERR=1
fi

if [ ! -z $ERR ] ; then
    exit 1
fi

if [ -z $EDITOR ] ; then
    EDITOR="vim -n"
elif [ $( expr \( "X$EDITOR" : ".*vim.*" \) ) -gt 0 ] ; then
    EDITOR="$EDITOR -n"
fi

TEMPFILE=$( mktemp -t $(whoami).XXXX ) || exit 1
trap "rm -f $TEMPFILE" 0 1 2 5 15

encryptFile()
{
    NEWKEY=$( openssl rand -base64 32 )
    echo $NEWKEY | openssl rsautl -encrypt -pubin -inkey $PUBKEY | openssl enc -base64 -e > $VFILE
    echo $NEWKEY | openssl enc -e -a -aes-256-cbc -salt -pass stdin -in $TEMPFILE >> $VFILE
    unset NEWKEY
}

if [ ! -s $VFILE ] && [ -z $ENCRYPT ] && [ -z $DECRYPT ] ; then
    $EDITOR $TEMPFILE
    encryptFile
    exit 0
fi

if [ ! -z $ENCRYPT ] ; then
    cat $VFILE > $TEMPFILE
    VFILE=$( mktemp -t $(whoami).XXXX ) || exit 1
    encryptFile
    cat $VFILE
    rm -f $VFILE
    exit 0
fi

KEY=$( head -11 $VFILE | openssl enc -base64 -d | openssl rsautl -decrypt -inkey $PRIVKEY 2> $TEMPFILE )
if [ $? -ne 0 ] ; then
    if [ ! -z "$( grep "RSA operation error" $TEMPFILE )" ] ; then
        echo "Incorrect key pair for: $VFILE"
    else
        cat $TEMPFILE
    fi
    exit 1
fi

ENCFILE=$( mktemp -t $(whoami).XXXX ) || exit 1
tail -n +12 $VFILE > $ENCFILE

echo $KEY | openssl enc -d -a -aes-256-cbc -salt -pass stdin -in $ENCFILE > $TEMPFILE ; unset KEY ; rm -f $ENCFILE

if [ ! -z $DECRYPT ] ; then
    cat $TEMPFILE
    exit 0
fi

$EDITOR $TEMPFILE 

encryptFile

exit 0


==========
myvault.sh
==========

:Version: 1.0.0
:Web: http://www.dctrwatson.com/2010/10/introducting-myvault
:Download: http://github.com/dctrwatson/myvault

myvault.sh is a shell script for editing an ecrypted text file stored as ``$HOME/.myvault``

The text file is symmetrically encrypted using aes-256 and a random 32 character
password that is generated every time the script is run. The password is then
encrypted using an RSA key (Default: ``$HOME/.ssh/id_rsa``)

It can also be used to encrypt and decrypt arbitrary files using the same
method.

Requirements
============
- OpenSSL

Setup
=====

If you do not already have an RSA key generated, use the following command to do so.::

    $ ssh-keygen -t rsa -b 4096

* Note: It's **HIGHLY RECOMMENDED** to use a passphrase on the key.

Usage
=====

``myvault.sh [-f FILE] [-k KEYFILE] [-p KEYFILE] [-e] [-d] [in_file] [> out_file]``

``-f FILE``
    Specify an encrypted text file (Default: ``$HOME/.myvault``)  

``-k KEYFILE``
    Specify a private RSA key file (Default: ``$HOME/.ssh/id_rsa``)  

``-p KEYFILE``
    Specify a public key file (Default: ``{PRIVATE_KEYFILE}.pub.pem``)

``-e``
    Encrypt ``in_file`` to STDOUT

``-d``
    Decrypt ``in_file`` to STDOUT

Notes
-----
``myvault.sh`` uses the **EDITOR** and **TMPDIR** environment variables for some configuration.

If **EDITOR** is not defined, it defaults to ``vim``.

.. # vim: syntax=rst expandtab tabstop=4 shiftwidth=4 shiftround

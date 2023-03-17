# /etc/skel/.bashrc
#
# This file is sourced by all *interactive* bash shells on startup,
# including some apparently interactive shells such as scp and rcp
# that can't tolerate any output.  So make sure this doesn't display
# anything or bad things will happen !

# Test for an interactive shell.  There is no need to set anything
# past this point for scp and rcp, and it's important to refrain from
# outputting anything in those cases.
if [[ $- != *i* ]] ; then
        # Shell is non-interactive.  Be done now!
        return
fi

# JVM Ops
alias jvm-start='/$HOME/jvm_ops.sh --start'
alias jvm-stop='/$HOME/jvm_ops.sh --stop'
alias jvm-restart='/$HOME/jvm_ops.sh --restart'
alias jvm-foreground='/$HOME/jvm_ops.sh --foreground'
alias jvm-deploy='/$HOME/jvm_ops.sh --deploy'
alias jvm-build='/$HOME/jvm_ops.sh --build'
alias jvm-build-deploy='/$HOME/jvm_ops.sh --build-deploy'

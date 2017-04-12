##############################################################################
#
# .bashrc	Aliases and functions
#
# R02 25aug06	MoHo	Fix projects, dir funcs, prompts, cleanup deprecated
#
##############################################################################

#>> echo "executing .bashrc, PROJENV=$PROJENV" 1>&2

### Source global definitions ###
[ -f /etc/bashrc ] && . /etc/bashrc

### Define Directory History ###
if [ -z "$_dh" ]
then
	_dh=$PWD
	typeset -i _hs=${DIRHISTORY:-20} _hp=0 _sp=0
fi



#
#	FUNCTIONS
#

### calc : calculate some arithmetic expression ###
calc()
{
	local i
	typeset -i i

	let "i = $*"
	echo -e $i
}

### Change Working Directory (cd) ###
cwd()
{
	local p_disp=false p_nl
	local j k

	case "$1" in
		[+-][1-9]*)
			typeset -i j=_hp+1 k=0$1
			((j > _hs)) && let j=_hs
			if ((k <= j)) && ((k > -j))
			then
				p_disp=true
				cd "${_dh[($_hp$1)%$j]}"
			else
				printf "Out of range\n" 1>&2
			fi
			;;
		/*)	p_disp=true
			cd "$*"
			;;
		"")	p_disp=true
			cd
			;;
		*)	cd "$*"
	esac && \
		{
		$p_disp && echo $PWD

		p_nl="$_ps0"
		if ((${#PWD} > ${psDirLenMax:-30}))
		then
			_ps0="\n"
		else
			_ps0=
		fi
		[ "$p_nl" == "$_ps0" ] || eval "$_ps1"

		[ "${_dh[_hp]}" == "$PWD" ] || _dh[++_hp%_hs]="$PWD"
		}
}

### Display history (dh) ###
dirhist()
{
	local i j

	typeset -i i=0 j=_hp+1

	((j > _hs)) && let j=_hs
	while (((++i) < j+1))
	do
		printf "%2d  %3d\t: ${_dh[($_hp+$i)%$j]}\n" $i $((i-j))
	done
}

### Change Directory from menu of dir history ###
dirmenu()
{
	dirhist
	printf ">> cd: "
	read n
	case $n in
		[+-]*)	cwd $n ;;
		[1-9]*)	cwd +$n ;;
		*)	echo $PWD
	esac
}

### Set Informix Server ###
dbs()
{
	(( $# > 0 )) && export INFORMIXSERVER=$1
	echo "Server = $INFORMIXSERVER"
}

### nbase : converts a stream of numbers prefixed with b#, 0 or 0x to $1 base
nbase()
{
	local n=0
	local p_fmt="$1"

	typeset -i n
	shift
	for n in $*
	do
		printf "%$p_fmt " $n
	done
	echo -e
}

### Project Control ###
project()
{
	case $# in
		0)	echo $PROJECT
			;;
		*)	case "$1" in
				-l*)	projlist
					return
					;;
				-)	project=home
					;;
				*)	project=$1
			esac

			#### Search for projects - local >> global ####
			[ -f /etc/Projects/$project ] && projdir=/etc/Projects
			[ -f $PROJDIR/$project ] && projdir=$PROJDIR
			if [ $projdir ]
			then
				PROJECT=$project
				PROJENV=$projdir/$project
				[ "$EXPORT" ] && unset $EXPORT

				export	_NEWGRP=true HOME=$LOGHOME
				. $PROJENV
			else
				echo -e "\007Unknown project: $project\n" 1>&2
				projlist 1>&2
			fi
	esac
}

### List Projects ###
projlist()
{
	echo -e "\nPROJECTS\n"
	[ -d /etc/Projects ] && echo -e "Standard:\n`ls -C /etc/Projects`\n"
	[ -d ${PROJDIR:-+} ] && echo -e "Local:\n`ls -C $PROJDIR`\n"
}




#
#	ALIASES
#

 alias	2oct='nbase o'
 alias	2dec='nbase d'
 alias	2hex='nbase x'
 alias	cd=cwd
 alias	dh=dirhist
 alias	dm=dirmenu
 alias	dba=dbaccess
 alias	:e='$EDITOR'
 alias	echo='echo -e'
 alias	ex_='echo EXINIT: $EXINIT 1>&2'
 alias	ex0='unset EXINIT ; echo EXINIT: $EXINIT 1>&2'
 alias	ex4='EXINIT=$EX4 ; echo EXINIT: $EXINIT 1>&2'
 alias	ex8='EXINIT=$EX8 ; echo EXINIT: $EXINIT 1>&2'
 alias  h=history
 alias  j=jobs
 alias	lf='ls -CF'
 alias	ll='ls -las'
 alias	login='exec login'
 alias	m=less
 alias	mx='chmod +x'
 alias	new_group='[ $_NEWGRP ] && unset _NEWGRP && exec newgrp'
 alias	onm=onmonitor
 alias	proj='project'
 alias	restart='exec login $LOGNAME'
 alias	rpath='PATH=$_PATH'
 alias	rtty='stty $STTY'
 alias	sql='dbaccess $DB'
 alias	t=tail
 alias	tab4='pr -t -e4'
 alias	ualias='alias | comm -23 - ~/.except'
 alias	updProf='cp -p /home/default/.bash* $LOGHOME'
 alias  v='set -o vi'
 alias	vi4='EXINIT=$EX4 vi'
 alias	vi8='EXINIT=$EX8 vi'
 alias	xalias='alias | sed -e "s/=.*//"'




#
#	INITIALIZE (each shell)
#

### Prompt update ###
#_ps1='PS1="\[$_ps\]$HOST:$psDirPrompt$_ps0$SHLVL:\!$_ID>\[$_pe\] "'
#eval "$_ps1"
#[ "$PROMPT_COMMAND" ] &&
#	PROMPT_COMMAND=${PROMPT_COMMAND/:*\}/ [${PROJECT}] $\{PWD\}}


### Set project environment (after newgrp) ###
if [ $PROJENV ]
then
	export ProjEnv=$PROJENV HOME
	PROJENV=
	. $ProjEnv
	umask 02

	### Kludge to prime project .bashrc ###
	[ -f ~/.bashrc ] || echo '[ -f "$ENV" ] && . "$ENV"' > ~/.bashrc
fi

### Set other local opts ###
shopt -s lithist
set -o vi


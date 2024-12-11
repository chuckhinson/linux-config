# ~/.bash_aliases

alias di='docker images --format '\''{{.ID}}  {{.Repository}}:{{.Tag}}'\'
alias k='kubectl'
alias prof='env | grep AWS; aws sts get-caller-identity'

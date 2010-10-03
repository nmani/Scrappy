# ABSTRACT: All Powerful Web Harvester, Spider, Scraper in a Box

use strict;
use warnings;

package Scrappy::Doo;
use Scrappy qw/:syntax/;
use Array::Unique;
use Try::Tiny;

BEGIN {
    use Exporter();
    use vars qw( @ISA @EXPORT );
    @ISA    = qw( Exporter );
    @EXPORT = qw(
        start
        queue
        cursor
    );
}

our @_queue = ();
tie @_queue, 'Array::Unique';

our $_cursor = 0;
sub cursor {
    $_cursor = $_[0] if $_[0];
    return $_cursor;
}

sub out {
    print "[fetch] ", shift, "\n"
}

sub err {
    print "[error] ", shift, "\n"
}

sub queue {
    return @_ ? push @_queue, @_ : @_queue;
}

sub start {
    my ($url, $actions) = @_;
    
    init;
    user_agent random_ua;
    $_queue[cursor()] = $url;
    
    doPage:
    
    try {
        get $_queue[cursor()];
    }
    catch {
        err "problem fetching " . $_queue[cursor()];
        goto nextPage;
    };
    
    try {
        loaded;
    }
    catch {
        err "problem loading " . $_queue[cursor()];
        goto nextPage;
    };
    
    out "fetching page " . $_queue[cursor()];
    
    # process actions
    if ("hash" eq lc ref $actions) {
        while (my($selector, $function) = each(%{$actions})) {
            my $findings = grab $selector, tattr();
            foreach (@{$findings}) {
                $function->($_);
            }
        }
    }
    
    nextPage:
    goto doPage if $_queue[++$_cursor];
}

sub tattr {
    return {
        'abbr'           => '@abbr',
        'accept-charset' => '@accept',
        'accept'         => '@accept',
        'accesskey'      => '@accesskey',
        'action'         => '@action',
        'align'          => '@align',
        'alink'          => '@alink',
        'alt'            => '@alt',
        'archive'        => '@archive',
        'axis'           => '@axis',
        'background'     => '@background',
        'bgcolor'        => '@bgcolor',
        'border'         => '@border',
        'cellpadding'    => '@cellpadding',
        'cellspacing'    => '@cellspacing',
        'char'           => '@char',
        'charoff'        => '@charoff',
        'charset'        => '@charset',
        'checked'        => '@checked',
        'cite'           => '@cite',
        'class'          => '@class',
        'classid'        => '@classid',
        'clear'          => '@clear',
        'code'           => '@code',
        'codebase'       => '@codebase',
        'codetype'       => '@codetype',
        'color'          => '@color',
        'cols'           => '@cols',
        'colspan'        => '@colspan',
        'compact'        => '@compact',
        'content'        => '@content',
        'coords'         => '@coords',
        'data'           => '@data',
        'datetime'       => '@datetime',
        'declare'        => '@declare',
        'defer'          => '@defer',
        'dir'            => '@dir',
        'disabled'       => '@disabled',
        'enctype'        => '@enctype',
        'face'           => '@face',
        'for'            => '@for',
        'frame'          => '@frame',
        'frameborder'    => '@frameborder',
        'headers'        => '@headers',
        'height'         => '@height',
        'href'           => '@href',
        'hreflang'       => '@hreflang',
        'hspace'         => '@hspace',
        'http'           => '@http-equiv',
        'id'             => '@id',
        'ismap'          => '@ismap',
        'label'          => '@label',
        'lang'           => '@lang',
        'language'       => '@language',
        'link'           => '@link',
        'longdesc'       => '@longdesc',
        'marginheight'   => '@marginheight',
        'marginwidth'    => '@marginwidth',
        'maxlength'      => '@maxlength',
        'media'          => '@media',
        'method'         => '@method',
        'multiple'       => '@multiple',
        'name'           => '@name',
        'nohref'         => '@nohref',
        'noresize'       => '@noresize',
        'noshade'        => '@noshade',
        'nowrap'         => '@nowrap',
        'object'         => '@object',
        'onblur'         => '@onblur',
        'onchange'       => '@onchange',
        'onclick'        => '@onclick',
        'ondblclick'     => '@ondblclick',
        'onfocus'        => '@onfocus',
        'onkeydown'      => '@onkeydown',
        'onkeypress'     => '@onkeypress',
        'onkeyup'        => '@onkeyup',
        'onload'         => '@onload',
        'onmousedown'    => '@onmousedown',
        'onmousemove'    => '@onmousemove',
        'onmouseout'     => '@onmouseout',
        'onmouseover'    => '@onmouseover',
        'onmouseup'      => '@onmouseup',
        'onreset'        => '@onreset',
        'onselect'       => '@onselect',
        'onsubmit'       => '@onsubmit',
        'onunload'       => '@onunload',
        'profile'        => '@profile',
        'prompt'         => '@prompt',
        'readonly'       => '@readonly',
        'rel'            => '@rel',
        'rev'            => '@rev',
        'rows'           => '@rows',
        'rowspan'        => '@rowspan',
        'rules'          => '@rules',
        'scheme'         => '@scheme',
        'scope'          => '@scope',
        'scrolling'      => '@scrolling',
        'selected'       => '@selected',
        'shape'          => '@shape',
        'size'           => '@size',
        'span'           => '@span',
        'src'            => '@src',
        'standby'        => '@standby',
        'start'          => '@start',
        'style'          => '@style',
        'summary'        => '@summary',
        'tabindex'       => '@tabindex',
        'target'         => '@target',
        'text'           => '@text',
        'title'          => '@title',
        'type'           => '@type',
        'usemap'         => '@usemap',
        'valign'         => '@valign',
        'value'          => '@value',
        'valuetype'      => '@valuetype',
        'version'        => '@version',
        'vlink'          => '@vlink',
        'vspace'         => '@vspace',
        'width'          => '@width',
        
        'text'           => 'TEXT',
        'html'           => 'HTML',
    };
}

1;
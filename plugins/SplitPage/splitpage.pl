# A plugin for adding "SplitPage" functionality.
# Copyright (c) 2016 ARK-Web Co.,Ltd.
# MIT License

package MT::Plugin::SplitPage;

use strict;
use MT;
use MT::Template::Context;
use MT::I18N;

use vars qw( $VERSION );
$VERSION = '2.0';

use base qw( MT::Plugin );

our $SPLIT_PAGE_TARGET_BLOCK_START = '<!-- SplitPage Target Contents Start -->';
our $SPLIT_PAGE_TARGET_BLOCK_END = '<!-- SplitPage Target Contents End -->';
our $SPLIT_PAGE_LISTS = '<!-- SplitPage PageLists -->';

###################################### Init Plugin #####################################

my $plugin = new MT::Plugin::SplitPage({
    id => 'SplitPage',
    name => 'SplitPage',
    author_name => 'ARK-Web co., ltd.',
    author_link => 'https://www.ark-web.jp/',
    version => $VERSION,
    description => 'ページ（エントリー、またはウェブページ）を本文中の任意の箇所で複数ページに分割するプラグイン',
    plugin_link => 'https://github.com/ARK-Web/mt_plugin_SplitPages',
});

MT->add_plugin($plugin);
MT->add_callback('BuildPage', 4, $plugin, \&_split_page);

sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        tags => {
            function => {
                'SplitPageLists' => \&_split_page_lists,
            },
            modifier => {
                'split' => \&_prepare_split,
                'hide' => \&_erase_split,
                'splitpage_cut' => \&_cut_split,
            },
        },
    });
}

sub _split_page {
    my $eh = shift;
    my %args = @_;

    my $ctx = $args{Context};
    my $file_info = $args{FileInfo};
    my $file_path = $file_info->file_path;

    &_set_file_informations( $ctx, $file_path );

    my $blog = $ctx->stash('blog');
    my $url = $file_info->url;

    # process for Entry and WebPage
    my $archive_type = $file_info->archive_type;
    if ( $archive_type ne 'Individual' && $archive_type ne 'Page' ) {
        return;
    }

    # split content and generate splited pages
    my $entry = $args{entry};
    my $body = $entry->text;
    $body = &_apply_text_filters($ctx, $entry, $body);
    my @splited_bodies = split(/\[\[SplitPage\]\]/i, $body);
    my $count = @splited_bodies;

    # no process
    if ( $count < 2 ) {
        return;
    }

    # parse content
    my $content = $args{Content};
    my @contents = split(/$SPLIT_PAGE_TARGET_BLOCK_START/, $$content);
    my $contents_header = $contents[0];
    my $contents_main = $contents[1];
    @contents = ();
    @contents = split(/$SPLIT_PAGE_TARGET_BLOCK_END/, $$content);
    my $contents_footer = $contents[1];

    # generate 1st page
    $$content = $contents_header . $splited_bodies[0] . $contents_footer;
    my $first_file_page_lists = &_get_nth_file_page_lists($count, $ctx, 1);
    $$content =~ s/\Q$SPLIT_PAGE_LISTS\E/$first_file_page_lists/g;

    my $splitpage_header = $ctx->{__stash}{vars}{splitpage_header} || '';
    my $splitpage_footer = $ctx->{__stash}{vars}{splitpage_footer} || '';

    # generate Nth page
    for ( my $i=2; $i<=$count; $i++) {
        my $nth_file_path = &_get_nth_file_path($ctx, $i);
        my $nth_file_page_lists = &_get_nth_file_page_lists($count, $ctx, $i);
        my $nth_file_content = $contents_header . $splitpage_header . $splited_bodies[$i-1] . $splitpage_footer . $contents_footer;
        $nth_file_content =~ s/\Q$SPLIT_PAGE_LISTS\E/$nth_file_page_lists/g;
        my $file_mgr = $blog->file_mgr;
        $file_mgr->put_data($nth_file_content, "${nth_file_path}.new");
        $file_mgr->rename("${nth_file_path}.new", $nth_file_path);
    }
}

sub _split_page_lists {
    my( $ctx, $args, $cond ) = @_;

    my $list_config = $ctx->stash('SplitPage::list_config');
    if( !$list_config ) {
        $list_config = {};
        $ctx->stash('SplitPage::list_config',$list_config);
    }

    $list_config->{link_start} = $args->{link_start} || q{};
    $list_config->{link_end} = $args->{link_end} || q{};

    return $SPLIT_PAGE_LISTS;
}

sub _prepare_split {
    my( $text, $args, $ctx ) = @_;
    $text =  $SPLIT_PAGE_TARGET_BLOCK_START . "\n" . $text . "\n" . $SPLIT_PAGE_TARGET_BLOCK_END;
    return $text;
}

sub _erase_split {
    my( $text, $args, $ctx ) = @_;
    $text =~ s/\[\[SplitPage\]\]/\n/iog;
    return $text;
}

sub _cut_split {
    my( $text, $args, $ctx ) = @_;
    $text =~ s/\[\[SplitPage\]\].*$/\n/iosg;
    return $text;
}

sub _set_file_informations {
    my ( $ctx, $file_path ) = @_;

    my $file_informations = {};
    $ctx->stash('SplitPage::file_informations', $file_informations);

    my $blog = $ctx->stash('blog');
    my $site_url = $blog->site_url;
    $site_url = $site_url . '/' unless ($site_url =~ /[\/\\]$/);
    my $site_path = $blog->site_path;
    $site_path = $site_path . '/' unless ($site_path =~ /[\/\\]$/);
    $file_path = substr($file_path, length($site_path));

    my ( $file_name, $file_ext );
    if ( $file_path =~ /^[\/\\]?(.*)\.(.*?)$/ ) {
	$file_name = $1;
	$file_ext = $2;
    } else {
	$file_name = $file_path;
	$file_ext = '';
    }

    # set on stash
    $file_informations->{'site_path'} = $site_path;
    $file_informations->{'site_url'} = $site_url;
    $file_informations->{'file_path'} = $file_path;
    $file_informations->{'file_name'} = $file_name;
    $file_informations->{'file_ext'} = $file_ext;
}

# Nページ目のファイルパスを生成する
sub _get_nth_file_path {
    my ( $ctx, $n ) = @_;

    my $file_informations = $ctx->stash('SplitPage::file_informations');

    return sprintf("%s%s-%s.%s", $file_informations->{'site_path'}, $file_informations->{'file_name'}, $n, $file_informations->{'file_ext'});
}

# Nページ目のURLを生成する
sub _get_nth_file_url {
    my ( $ctx, $n ) = @_;

    my $file_informations = $ctx->stash('SplitPage::file_informations');

    if ( $n == 1 ) {
        return sprintf("%s%s.%s", $file_informations->{'site_url'}, $file_informations->{'file_name'}, $file_informations->{'file_ext'});
    } else {
        return sprintf("%s%s-%s.%s", $file_informations->{'site_url'}, $file_informations->{'file_name'}, $n, $file_informations->{'file_ext'});
    }
}

# Nページ目のページングリンクを生成する
sub _get_nth_file_page_lists {
    my ( $count, $ctx, $n ) = @_;

    my $lists_str;
    my $list_config = $ctx->stash('SplitPage::list_config');

    for ( my $i=0; $i<$count; $i++ ) {
        if ( $n ne '' && $n == $i+1 ) {
            $lists_str .= sprintf(qq{%s<span class="current_page">%s</span>%s}, $list_config->{'link_start'}, $i+1, $list_config->{'link_end'});
        } else {
            my $link_href = &_get_nth_file_url($ctx, $i+1);
            $lists_str .= sprintf(qq{%s<a href="%s" class="link_page">%s</a>%s}, $list_config->{'link_start'}, $link_href, $i+1, $list_config->{'link_end'});
        }
    }

    return $lists_str;
}

sub _apply_text_filters {
    my ($ctx, $e, $text, $args) = @_;

    my $blog = $ctx->stash('blog');
    my $convert_breaks
        = exists $args->{convert_breaks} ? $args->{convert_breaks}
        : defined $e->convert_breaks     ? $e->convert_breaks
        : ( $blog ? $blog->convert_paras : '__default__' );
    if ($convert_breaks) {
        my $filters = $e->text_filters;
        push @$filters, '__default__' unless @$filters;
        $text = MT->apply_text_filters( $text, $filters, $ctx );
    }

    return $text;
}

1;

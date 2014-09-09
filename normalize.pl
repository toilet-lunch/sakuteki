#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
binmode STDOUT,":utf8";

use Unicode::Normalize;

#常用文字の正規表現コンパイル
my $basicCharReg = qr/\p{InHiragana}|\p{InKatakana}|[亜-腕]/;

#tweetテキストが書かれた入力ファイル
my $fileName = shift or die "usage: $0 <textfile>";

#入力テキストを1行ずつ処理する
open my $fh, "<:encoding(utf-8)", $fileName or die "$!:$fileName";
while (my $originText = <$fh>) {

    #改行コード削除
    chomp $originText;

    #Unicode正規化
    my $normalText = NFKC($originText);

    #先頭、末尾の空白を削除 (trim)
    $normalText = trim($normalText);

    #urlを削除
    $normalText = deleteURL($normalText);

    #ハッシュタグを削除
    $normalText = deleteHashTag($normalText);

    #tweet先頭にユーザIDがあれば削除
    $normalText = deleteResID($normalText);

    #5文字未満のtweetはノイズとして無視
    if ( length($normalText) < 5 ) { next; }

    #特殊な文字列や記号が4割以上だったら無視
    if ( isSpecialText($normalText,0.4) == 1 ) { next; }

    print $normalText . "\n";

}
close $fh;

#入力テキストの先頭・末尾の空白（の連続）を削除する
sub trim{
    my $text = shift;
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;
    return $text;
}

#tweet先頭のユーザIDを削除する
sub deleteResID{
    my $text = shift;
    $text =~ s/^\@[a-zA-Z0-9_]*\s?//;
    return $text;
}

#ひらがなカタカナ、及び第一水準
#上記に含まれない文字列がテキストの4割以上になっているか否か
sub isSpecialText{
    my ($text, $threshold) = @_;
    my $fullCharNum = length($text);
    $text =~ s/$basicCharReg//g;
    my $specialCharNum = length($text);

    #常用でない文字列または半角英数記号が4割以上含まれていたら1を返す
    if ( ($specialCharNum / $fullCharNum) >= $threshold) {
        return 1;
    }

    #そうでなければ0を返す
    return 0;
}

#ハッシュタグ(日本語含む)を削除
sub deleteHashTag{
    my $text = shift;
    $text =~ s/\#[^ ]* ?//sg;
    return $text;
}

#入力テキストからURL情報を削除する
sub deleteURL {
    my $text = shift;
    $text =~ s/https?:\/\/\p{InBasicLatin}*//sg;
    return $text;
}

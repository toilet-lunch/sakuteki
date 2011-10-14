#!/usr/bin/perl -w

use strict;
use Unicode::Normalize;
use utf8;
use Encode qw(encode_utf8 decode_utf8);
binmode STDOUT,":utf8";

#常用文字の正規表現コンパイル
my $basicCharReg = qr/\p{InHiragana}|\p{InKatakana}|[亜-腕]/;

#tweetテキストが書かれた入力ファイル
my $fileName = $ARGV[0];

#入力テキストを1行ずつ処理する
open(IN,"<:encoding(utf-8)",$fileName) or die "$!:$fileName";
while (my $originText = <IN>) {
    chomp($originText);

    #元テキスト
    my $originText = $ITEM[1];

    #Unicode正規化
    my $normalText = NFKC($originText) ;

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

    #記号が4割以上だったら無視

    #特殊な文字列や記号が4割以上だったら無視
    if ( isSpecialText($normalText,0.4) == 1 ) { next; }

    print $normalText . "\n";

}
close(IN);

#入力テキストの先頭・末尾の空白（の連続）を削除する
sub trim{
    my $text = $_[0];
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;
    return $text;
}

#tweet先頭のユーザIDを削除する
sub deleteResID{
    my $text = $_[0];
    $text =~ s/^\@[a-zA-Z0-9_]*\s?//;
    return $text;
}

#ひらがなカタカナ、及び第一水準
#上記に含まれない文字列がテキストの4割以上になっているか否か
sub isSpecialText{
    my $text = $_[0];
    my $threshold = $_[1] ;
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
    my $text = $_[0];
    $text =~ s/\#[^ ]* ?//sg;
    return $text;
}

#入力テキストからURL情報を削除する
sub deleteURL{
    my $text = $_[0];
    $text =~ s/https?:\/\/\p{InBasicLatin}*//sg;
    return $text;
}

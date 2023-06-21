#!/usr/bin/php
<?php

function avg(array $arr)
{
    return array_sum($arr)/count($arr);
}

function median(array $arr)
{
    sort($arr);
    return $arr[(int)(count($arr)/2)];
}

$reportJSON = @file_get_contents("report.json");;
if ($reportJSON) {
    $reportJSON = json_decode($reportJSON, JSON_OBJECT_AS_ARRAY);
}
else {
    $reportJSON = [];
}

if (!stream_isatty(STDIN)) {
    $INPUT = file_get_contents("php://stdin");

    $INPUTARR = array_filter(explode("\n", $INPUT));
    $INPUTARR = array_map(function($line) {
        preg_match("/^(?P<function>[^\s]+)[\s]+(?P<size>[0-9]+)[\s]+(?P<file>.+)$/", $line, $m);

        return [
            'function' =>   $m['function'],
            'size' =>       $m['size'],
            'file' =>       $m['file'],
        ];
    }, $INPUTARR);

    usort($INPUTARR, function ($a, $b) {
        return $a['size'] - $b['size'];
    });

    $ORIGINALINDEX = key(array_filter($INPUTARR, function($line) {
        return $line['function']=='original';
    }));
    $ORIGINAL = $INPUTARR[$ORIGINALINDEX];

    foreach ($INPUTARR as $index=>$functionDetails) {
        if (!array_key_exists($functionDetails['function'], $reportJSON)) {
            $reportJSON[$functionDetails['function']] = [
                'name' =>   $functionDetails['function'],
                'history' => [],
            ];
        }

        $key = md5(sprintf("%s", $ORIGINAL['file']));
        $reportJSON[$functionDetails['function']]['history'][$key] = [
            'key' => $key,
            'date' => date("Y-m-d H:i:s"),
            'file' => $ORIGINAL['file'],
            'compressedSize' =>                 $functionDetails['size'],
            'compressionPercentage' =>          100*$functionDetails['size']/$ORIGINAL['size'],
            'overall:order' =>                  $index,
            'comparedToOriginal:isLarger' =>    ($index>$ORIGINALINDEX),
            'comparedToOriginal:isSmaller' =>   ($index<$ORIGINALINDEX),
        ];

    }

    file_put_contents("report.json", json_encode($reportJSON, JSON_PRETTY_PRINT));
}
else {
    $ORIGINAL = $reportJSON['original'];
    uasort($reportJSON, function($a, $b) {
        // $aarr = array_map(function($instance){
        //     return $instance['compressionPercentage'];
        // }, $a['history']);

        // $barr = array_map(function($instance){
        //     return $instance['compressionPercentage'];
        // }, $b['history']);

        // return 1000 * (avg($aarr) - avg($barr));

        $aarr = array_map(function($instance){
            return $instance['comparedToOriginal:isLarger'];
        }, $a['history']);

        $barr = array_map(function($instance){
            return $instance['comparedToOriginal:isLarger'];
        }, $b['history']);

        return count(array_filter($aarr)) - count(array_filter($barr)) ;
    });

    foreach ($reportJSON as $function=>$functionDetails) {
        printf("\n%s, %d files tested", $function, count($functionDetails['history']));

        $arr = array_map(function($instance){
            return $instance['compressionPercentage'];
        }, $functionDetails['history']);

        printf("\n    compressionPercentage min/max: %.1f%%/%.1f%%", min($arr), max($arr));
        printf("\n    compressionPercentage avg: %.1f%%", array_sum($arr)/count($arr));
        printf("\n    compressionPercentage median: %.1f%%", median($arr));


        $arr = array_map(function($instance){
            return $instance['overall:order'];
        }, $functionDetails['history']);

        printf("\n    overall:order min/max: %d/%d", min($arr), max($arr));
        printf("\n    overall:order avg: %d", avg($arr));
        printf("\n    overall:order median: %d", median($arr));


        $arr = array_map(function($instance){
            return $instance['comparedToOriginal:isLarger'];
        }, $functionDetails['history']);

        printf("\n    comparedToOriginal:isLarger: yes:%d, no:%d", count(array_filter($arr)), count($arr) - count(array_filter($arr)));
        printf("\n    comparedToOriginal:isLarger avg: %.1f%% tests were larger", 100*count(array_filter($arr))/count($arr));

        printf("\n");
    }
    printf("\n");
}


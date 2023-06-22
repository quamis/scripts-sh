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

ini_set('xdebug.var_display_max_depth', '10');
ini_set('xdebug.var_display_max_children', '256');
ini_set('xdebug.var_display_max_data', '1024');

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
    $INPUTARR = array_filter(array_map(function($line) {
        $regexp = "/^(?P<function>(shrink_[^\s]+|original))[\s]+(?P<time_start>[0-9]+)ns[\s]+(?P<time_end>[0-9]+)ns[\s]+(?P<size>[0-9]+)[\s]+(?P<file>.+)$/";
        preg_match($regexp, $line, $m);
        if (!$m) {
            $regexp = "/(?P<function>(shrink_[^\s]+|original))[\s]+(?P<time_start>[0-9]+)ns[\s]+(?P<time_end>[0-9]+)ns[\s]+(?P<size>[0-9]+)[\s]+(?P<file>.+)$/";
            preg_match($regexp, $line, $m);
        }

        if (!$m) {
            return false;
        }



        return [
            'function' =>   $m['function'],
            'time_start' => $m['time_start'],
            'time_end' =>   $m['time_end'],
            'size' =>       $m['size'],
            'file' =>       $m['file'],
        ];
    }, $INPUTARR));

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
            'compression:percentage' =>          100*$functionDetails['size']/$ORIGINAL['size'],
            'compression:duration' =>           ($functionDetails['time_end'] - $functionDetails['time_start'])/1000000,
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
        //     return $instance['compression:percentage'];
        // }, $a['history']);

        // $barr = array_map(function($instance){
        //     return $instance['compression:percentage'];
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
            return $instance['compression:percentage'];
        }, $functionDetails['history']);

        printf("\n    compression:percentage min/max: %.1f%%/%.1f%%", min($arr), max($arr));
        printf("\n    compression:percentage avg: %.1f%%", array_sum($arr)/count($arr));
        printf("\n    compression:percentage median: %.1f%%", median($arr));


        $arr = array_map(function($instance){
            return $instance['overall:order'];
        }, $functionDetails['history']);

        printf("\n    overall:order min/max: %d/%d", min($arr), max($arr));
        printf("\n    overall:order avg: %d", avg($arr));
        printf("\n    overall:order median: %d", median($arr));


        $arr = array_map(function($instance){
            return $instance['compression:duration'];
        }, $functionDetails['history']);

        printf("\n    compression:duration min/max: %.3fs/%.3fs", min($arr), max($arr));
        printf("\n    compression:duration avg: %.3fs", array_sum($arr)/count($arr));
        printf("\n    compression:duration median: %.3fs", median($arr));


        $arr = array_map(function($instance){
            return $instance['comparedToOriginal:isLarger'];
        }, $functionDetails['history']);

        printf("\n    comparedToOriginal:isLarger: yes:%d, no:%d", count(array_filter($arr)), count($arr) - count(array_filter($arr)));
        printf("\n    comparedToOriginal:isLarger avg: %.1f%% tests were larger", 100*count(array_filter($arr))/count($arr));


        printf("\n");
    }
    printf("\n");
}


"""Uygulamanın gönderdiği verilerin doğrulanması.

Alan adları Flutter tarafındaki haritalarla birebir aynıdır (camelCase).
"""

from rest_framework import serializers


class CountsField(serializers.DictField):
    """Anahtar → sayı haritası, ör. {"animals": 3}."""

    child = serializers.IntegerField(min_value=0)

    def to_internal_value(self, data):
        value = super().to_internal_value(data)
        if len(value) > 50 or any(len(k) > 50 for k in value):
            raise serializers.ValidationError('Çok fazla ya da çok uzun anahtar')
        return value


class ProfileSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=100, allow_blank=True)
    email = serializers.CharField(max_length=254, allow_blank=True)
    userType = serializers.CharField(max_length=50, allow_blank=True)
    createdAt = serializers.DateTimeField()


class StatsSerializer(serializers.Serializer):
    totalCorrect = serializers.IntegerField(min_value=0)
    totalWrong = serializers.IntegerField(min_value=0)
    difficultyHistory = serializers.ListField(
        child=serializers.IntegerField(min_value=0, max_value=2), max_length=1000)
    startingDifficulty = serializers.IntegerField(min_value=0, max_value=2)
    pin = serializers.RegexField(r'^\d{4}$')
    totalAsrAttempts = serializers.IntegerField(min_value=0)
    exactAsrMatches = serializers.IntegerField(min_value=0)
    totalLatencyMs = serializers.IntegerField(min_value=0)
    latencyHistory = serializers.ListField(
        child=serializers.IntegerField(min_value=0), max_length=1000)
    categoryWrong = CountsField()
    categoryTotal = CountsField()
    childAge = serializers.IntegerField(min_value=2, max_value=5)


class RewardsSerializer(serializers.Serializer):
    totalCorrect = serializers.IntegerField(min_value=0)
    earnedIds = serializers.ListField(
        child=serializers.CharField(max_length=50), max_length=50)
    puzzlePieces = CountsField(child=serializers.IntegerField(min_value=0, max_value=9))


class LivesSerializer(serializers.Serializer):
    lives = serializers.IntegerField(min_value=0, max_value=5)

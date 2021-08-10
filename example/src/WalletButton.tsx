import React from 'react';
import { View, StyleSheet, TouchableOpacity, Text } from 'react-native';

export default function WalletButton({ onPress }) {
  return (
    <TouchableOpacity onPress={onPress}>
      <View style={styles.wrapper}>
        <Text style={styles.text}>Add card to wallet</Text>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    marginBottom: 28,
    height: 58,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#000',
  },
  icon: {
    marginRight: 10,
  },
  text: {
    color: '#fff',
  },
});

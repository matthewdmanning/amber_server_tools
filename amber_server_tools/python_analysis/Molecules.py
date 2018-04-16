class DnaMole:
    sequence1 = ''
    sequence2 = ''

    strand1_length = len(sequence1)
    strand2_length = len(sequence2)

    wc_pairs = {"DA": "DT", "DT": "DA", "DC": "DG", "DG": "DC"}

    def check_wc_pairing(self):
        wc_pairing = True
        for bp_index, base1 in enumerate(self.sequence1):
            if base1 == self.wc_pairs[self.sequence2[self.strand2_length - bp_index]]:
                continue
            else:
                print('This DNA molecule has non-WC base pairing at position {}. Bases: {}p{}'.format(bp_index), base1,
                      self.sequence2[self.strand2_length - bp_index])
                wc_pairing = False
        return wc_pairing

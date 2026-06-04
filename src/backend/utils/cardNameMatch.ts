export const normalizeCardName = (name: string | null | undefined): string =>
    (name ?? '').trim().toLowerCase();

export const cardNamesMatch = (
    a: string | null | undefined,
    b: string | null | undefined,
): boolean => {
    const na = normalizeCardName(a);
    const nb = normalizeCardName(b);
    return na.length > 0 && na === nb;
};
